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

function StateNode{P}(policy::AbstractMCTSPlanner{P}, s)
    S = state_type(P)
    A = action_type(P)
    ns = StateActionNode{A}[StateActionNode{A}(a,
                                               init_N(policy.solver.init_N, policy.mdp, s, a),
                                               init_Q(policy.solver.init_Q, policy.mdp, s, a)) 
                            for a in iterator(actions(policy.mdp, s))]
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
        Specifies how much the solver should explore.
        In the UCB equation, Q + c*sqrt(log(t/N)), c is the exploration constant.
        default: 1.0

    rng::AbstractRNG:
        Random number generator

    estimate_value::Any (rollout policy)
        Function, object, or number used to estimate the value at the leaf nodes.
        If this is a function `f`, `f(mdp, s, depth)` will be called to estimate the value.
        If this is an object `o`, `estimate_value(o, mdp, s, depth)` will be called.
        If this is a number, the value will be set to that number
        default: RolloutEstimator(RandomSolver(rng))

    init_Q::Any
        Function, object, or number used to set the initial Q(s,a) value at a new node.
        If this is a function `f`, `f(mdp, s, a)` will be called to set the value.
        If this is an object `o`, `init_Q(o, mdp, s, a)` will be called.
        If this is a number, Q will be set to that number
        default: 0.0

    init_N::Any
        Function, object, or number used to set the initial N(s,a) value at a new node.
        If this is a function `f`, `f(mdp, s, a)` will be called to set the value.
        If this is an object `o`, `init_N(o, mdp, s, a)` will be called.
        If this is a number, N will be set to that number
        default: 0

    enable_tree_vis::Bool:
        If this is true, extra information needed for tree visualization will
        be recorded. If it is false, the tree cannot be visualized.
        default: false
"""
type MCTSSolver <: AbstractMCTSSolver
	n_iterations::Int64
	depth::Int64
	exploration_constant::Float64
    rng::AbstractRNG
    estimate_value::Any
    init_Q::Any
    init_N::Any
    enable_tree_vis::Bool
end

"""
    MCTSSolver()

Use keyword arguments to specify values for the fields.
"""
function MCTSSolver(;n_iterations::Int64 = 100, 
                     depth::Int64 = 10,
                     exploration_constant::Float64 = 1.0,
                     rng = Base.GLOBAL_RNG,
                     estimate_value::Any = RolloutEstimator(RandomSolver(rng)),
                     init_Q = 0.0,
                     init_N = 0,
                     enable_tree_vis::Bool=false)
    return MCTSSolver(n_iterations, depth, exploration_constant, rng, estimate_value, init_Q, init_N, enable_tree_vis)
end

type MCTSPlanner{P<:Union{MDP,POMDP}, S, A, SE, RNG} <: AbstractMCTSPlanner{P}
	solver::MCTSSolver # containts the solver parameters
	mdp::P # model
    tree::Dict{S, StateNode{A}} # the search tree
    solved_estimate::SE
    rng::RNG
end

function MCTSPlanner(solver::MCTSSolver, mdp::Union{POMDP,MDP})
    tree = Dict{state_type(mdp), StateNode{action_type(mdp)}}()
    se = convert_estimator(solver.estimate_value, solver, mdp)
    return MCTSPlanner(solver, mdp, tree, se, solver.rng)
end


"""
Delete existing decision tree.
"""
function clear_tree!{S,A}(p::MCTSPlanner{S,A}) p.tree = Dict{S, StateNode{A}}() end


# no computation is done in solve - the solver is just given the mdp model that it will work with
POMDPs.solve(solver::MCTSSolver, mdp::Union{POMDP,MDP}) = MCTSPlanner(solver, mdp)

@POMDP_require POMDPs.action(policy::AbstractMCTSPlanner, state) begin
    @subreq simulate(policy, state, policy.solver.depth)
end

function POMDPs.action(policy::AbstractMCTSPlanner, state)
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

function POMDPs.action(policy::AbstractMCTSPlanner, state, action)
  POMDPs.action(policy, state)
end

function simulate(policy::AbstractMCTSPlanner, state, depth::Int64)
    # model parameters
    mdp = policy.mdp
    discount_factor = discount(mdp) 
    rng = policy.rng

    # once depth is zero return
    if depth == 0 || isterminal(policy.mdp, state)
        return 0.0
    end

    # if unexplored state add to the tree and run rollout
    if !hasnode(policy, state)
        newnode = insert_node!(policy, state)
        return estimate_value(policy.solved_estimate, policy.mdp, state, depth)
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

@POMDP_require simulate(policy::AbstractMCTSPlanner, state, depth::Int64) begin
    mdp = policy.mdp
    P = typeof(mdp)
    S = state_type(P)
    A = action_type(P)
    @req discount(::P)
    @req isterminal(::P, ::S)
    @subreq insert_node!(policy, state)
    @subreq estimate_value(policy.solved_estimate, mdp, state, depth)
    @req generate_sr(::P, ::S, ::A, ::typeof(policy.rng))
    @req isequal(::S, ::S) # for hasnode
    @req hash(::S) # for hasnode
end


# these functions are here so that they can be overridden by the aggregating solver
hasnode(policy::AbstractMCTSPlanner, s) = haskey(policy.tree, s)

function insert_node!(policy::AbstractMCTSPlanner, s)
    newnode = StateNode(policy, s)
    policy.tree[s] = newnode
    if policy.solver.enable_tree_vis
        for sanode in newnode.sanodes
            sanode._vis_stats = Set()
        end
    end
    return newnode
end

@POMDP_require insert_node!(policy::AbstractMCTSPlanner, s) begin
    # from the StateNode constructor
    P = typeof(policy.mdp)
    A = action_type(P)
    S = typeof(s)
    IQ = typeof(policy.solver.init_Q)
    if !(IQ <: Number) && !(IQ <: Function)
        @req init_Q(::IQ, ::P, ::S, ::A)
    end
    IN = typeof(policy.solver.init_N)
    if !(IN <: Number) && !(IN <: Function)
        @req init_N(::IN, ::P, ::S, ::A)
    end
    @req actions(::P, ::S)
    as = actions(policy.mdp, s)
    @req iterator(::typeof(as))
    @req isequal(::S, ::S) # for tree[s]
    @req hash(::S) # for tree[s]
end

getnode(policy::AbstractMCTSPlanner, s) = policy.tree[s]
record_visit(policy::AbstractMCTSPlanner, sanode::StateActionNode, s) = push!(get(sanode._vis_stats), s)

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
