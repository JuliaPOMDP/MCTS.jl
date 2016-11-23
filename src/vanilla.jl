type StateActionNode{A}
    action::A
    N::Int
    Q::Float64
    _vis_stats::Nullable{Any} # for visualization, will be gibberish if data is not recorded
    StateActionNode(a, N0, Q0) = new(a, N0, Q0, Nullable{Any}())
end

# State node in the search tree
type StateNode{A}
    N::Int # number of visits to the node
    sanodes::Vector{StateActionNode{A}} # all of the actions and their statistics
end

function StateNode{S,A}(policy::AbstractMCTSPolicy{S,A}, s::S)
    ns = StateActionNode{A}[StateActionNode{A}(a, init_N(policy, s, a), init_Q(policy, s, a)) for a in iterator(actions(policy.mdp, s))]
    return StateNode{A}(0, ns)
end

"""
MCTS solver type

Fields:

    n_iterations::Int64
        Number of iterations during each action() call.
        default: 100

    depth::Int64:
        Maximum rollout horizon and tree depth.
        default: 10

    exploration_constant::Float64: 
        Specified how much the solver should explore.
        In the UCB equation, Q + c*sqrt(log(t/N)), c is the exploration constant.
        default: 1.0

    rng::AbstractRNG:
        Random number generator

    rollout_solver::Union{Solver,Policy}:
        Rollout policy or solver.
        If this is a Policy, it will be used directly in rollouts;
        If it is a Solver, solve() will be called when solve() is called on 
        the MCTSSolver
        default: RandomSolver(rng)

    prior_knowledge::Any:
        An object containing any prior knowledge. Implement estimate_value,
        init_N, and init_Q to use this.
        default: nothing

    enable_tree_vis::Bool:
        If this is true, extra information needed for tree visualization will
        be recorded. If it is false, the tree cannot be visualized.
        default: false
"""
type MCTSSolver <: AbstractMCTSSolver
	n_iterations::Int64
	depth::Int64 # the max depth of the tree
	exploration_constant::Float64 # constant balancing exploration and exploitation
    rng::AbstractRNG # random number generator
    rollout_solver::Union{Solver,Policy} # rollout policy
                                         # if this is a Solver, solve() will be called when solve() is called on the MCTSSolver;
                                         # if this is a Policy, it will be used directly
    prior_knowledge::Any # a custom object that encodes any prior knowledge about the problem - to be used in init_N, init_Q, and estimate_value
    enable_tree_vis::Bool # if true, will record data needed for visualization
end

"""
    MCTSSolver()

Use keyword arguments to specify values for the fields.
"""
function MCTSSolver(;n_iterations::Int64 = 100, 
                     depth::Int64 = 10,
                     exploration_constant::Float64 = 1.0,
                     rng = MersenneTwister(),
                     rollout_solver = RandomSolver(rng), # random policy is default
                     prior_knowledge = nothing,
                     enable_tree_vis::Bool=false)
    return MCTSSolver(n_iterations, depth, exploration_constant, rng, rollout_solver, prior_knowledge, enable_tree_vis)
end

type MCTSPolicy{S,A,PriorKnowledgeType} <: AbstractMCTSPolicy{S,A,PriorKnowledgeType}
	solver::MCTSSolver # containts the solver parameters
	mdp::Union{POMDP,MDP} # model
    rollout_policy::Policy # rollout policy
    tree::Dict{S, StateNode{A}} # the search tree

    MCTSPolicy()=new() # is it too dangerous to have this?
end

function MCTSPolicy{S,A}(solver::MCTSSolver, mdp::Union{POMDP{S,A},MDP{S,A}})
    p = MCTSPolicy{S,A,typeof(solver.prior_knowledge)}()
    fill_defaults!(p, solver, mdp)
    p
end

"""
Set members to suitable default values (broken out of the constructor so that it can be used elsewhere).
"""
function fill_defaults!{S,A}(p::MCTSPolicy{S,A}, solver::MCTSSolver=p.solver, mdp::Union{POMDP,MDP}=p.mdp)
    p.solver = solver
    p.mdp = mdp
    if isa(p.solver.rollout_solver, Solver)
        p.rollout_policy = solve(p.solver.rollout_solver, mdp)
    else
        p.rollout_policy = p.solver.rollout_solver
    end

    # pre-allocate
    p.tree = Dict{S, StateNode{A}}()
    return p
end

"""
Delete existing decision tree.
"""
function clear_tree!{S,A}(p::MCTSPolicy{S,A}) p.tree = Dict{S, StateNode{A}}() end

# no computation is done in solve - the solver is just given the mdp model that it will work with
function POMDPs.solve{S,A}(solver::MCTSSolver, mdp::Union{POMDP{S,A},MDP{S,A}}, policy::MCTSPolicy=MCTSPolicy{S,A,typeof(solver.prior_knowledge)}())
    fill_defaults!(policy, solver, mdp)
    return policy
end

function POMDPs.action(policy::AbstractMCTSPolicy, state)
    n_iterations = policy.solver.n_iterations
    depth = policy.solver.depth
    # build the tree
    for n = 1:n_iterations
        simulate(policy, state, depth)
    end
    # find the index of action with highest q val
    best = best_sanode_Q(getnode(policy, state))
    # use map to conver index to mdp action
    return best.action
end

function POMDPs.action(policy::AbstractMCTSPolicy, state, action)
  POMDPs.action(policy, state)
end


function simulate(policy::AbstractMCTSPolicy, state, depth::Int64)
    # model parameters
    mdp = policy.mdp
    discount_factor = discount(mdp) 
    rng = policy.solver.rng

    # once depth is zero return
    if depth == 0 || isterminal(policy.mdp, state)
        return 0.0
    end

    # if unexplored state add to the tree and run rollout
    if !hasnode(policy, state)
        newnode = insert_node!(policy, state)
        return estimate_value(policy, state, depth)
    end 
    # if previously visited node
    snode = getnode(policy, state)

    # pick action using UCT
    snode.N += 1 # increase number of node visits by one
    sanode = best_sanode_UCB(snode, policy.solver.exploration_constant)

    # transition to a new state
    sp, r = generate_sr(mdp, state, sanode.action, rng)
    
    if policy.solver.enable_tree_vis
        record_visit(policy, sanode, sp)
    end

    q = r + discount_factor * simulate(policy, sp, depth - 1)
    sanode.N += 1
    sanode.Q += ((q - sanode.Q) / (sanode.N)) # moving average of Q value
    return q
end

# these functions are here so that they can be overridden by the aggregating solver
hasnode(policy::AbstractMCTSPolicy, s) = haskey(policy.tree, s)
function insert_node!{S,A}(policy::AbstractMCTSPolicy{S,A}, s::S)
    newnode = policy.tree[deepcopy(s)] = StateNode(policy, s)
    if policy.solver.enable_tree_vis
        for sanode in newnode.sanodes
            sanode._vis_stats = Set()
        end
    end
    return newnode
end
getnode(policy::AbstractMCTSPolicy, s) = policy.tree[s]
record_visit(policy::AbstractMCTSPolicy, sanode::StateActionNode, s) = push!(get(sanode._vis_stats), s)

"""
Return the best action based on the Q score
"""
function best_sanode_Q(snode)
    best_Q = -Inf
    local best_sanode::StateActionNode
    for sanode in snode.sanodes
        if sanode.Q > best_Q
            best_Q = sanode.Q
            best_sanode = sanode
        end
    end
    return best_sanode
end

"""
Return the best action node based on the UCB score with exploration constant c
"""
function best_sanode_UCB(snode, c::Float64)
    best_UCB = -Inf
    best_sanode = snode.sanodes[1]
    sN = snode.N
    for sanode in snode.sanodes
        if sN == 1 && sanode.N == 0
            UCB = sanode.Q
        else
            UCB = sanode.Q + c*sqrt(log(sN)/sanode.N)
        end
        @assert !isnan(UCB)
        @assert !isequal(UCB, -Inf)
        if UCB > best_UCB
            best_UCB = UCB
            best_sanode = sanode
        end
    end
    return best_sanode
end
