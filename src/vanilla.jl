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
function StateNode{A}(mdp::POMDP, s)
    ns = StateActionNode{A}[StateActionNode{A}(a, 0, 0.0) for a in iterator(actions(mdp, s))] # TODO: mechanism for assigning N0, Q0
    return StateNode{A}(0, ns)
end

# MCTS solver type
type MCTSSolver <: AbstractMCTSSolver
	n_iterations::Int64	# number of iterations during each action() call
	depth::Int64 # the max depth of the tree
	exploration_constant::Float64 # constant balancing exploration and exploitation
    rng::AbstractRNG # random number generator
    rollout_solver::Union{Solver,Policy} # rollout policy
                                         # if this is a Solver, solve() will be called when solve() is called on the MCTSSolver;
                                         # if this is a Policy, it will be used directly
    enable_tree_vis::Bool # if true, will record data needed for visualization
end
# solver constructor
function MCTSSolver(;n_iterations::Int64 = 100, 
                     depth::Int64 = 10,
                     exploration_constant::Float64 = 1.0,
                     rng = MersenneTwister(),
                     rollout_solver = RandomSolver(rng), # random policy is default
                     enable_tree_vis::Bool=false)
    return MCTSSolver(n_iterations, depth, exploration_constant, rng, rollout_solver, enable_tree_vis)
end

# MCTS policy type
type MCTSPolicy{S,A} <: AbstractMCTSPolicy
	mcts::MCTSSolver # containts the solver parameters
	mdp::POMDP # model
    rollout_policy::Policy # rollout policy
    tree::Dict{S, StateNode{A}} # the search tree
    sim::MDPRolloutSimulator # for doing rollouts

    MCTSPolicy()=new() # is it too dangerous to have this?
end
# policy constructor
function MCTSPolicy{S,A}(mcts::MCTSSolver, mdp::MDP{S,A})
    p = MCTSPolicy{S,A}()
    fill_defaults!(p, mcts, mdp)
    p
end
# sets members to suitable default values (broken out of the constructor so that it can be used elsewhere)
function fill_defaults!{S,A}(p::MCTSPolicy{S,A}, solver::MCTSSolver=p.mcts, mdp::MDP{S,A}=p.mdp)
    p.mcts = solver
    p.mdp = mdp
    if isa(p.mcts.rollout_solver, Solver)
        p.rollout_policy = solve(p.mcts.rollout_solver, mdp)
    else
        p.rollout_policy = p.mcts.rollout_solver
    end

    # pre-allocate
    p.tree = Dict{S, StateNode{A}}()
    p.sim = MDPRolloutSimulator(rng=solver.rng, max_steps=0)
    return p
end

# no computation is done in solve - the solver is just given the mdp model that it will work with
function POMDPs.solve{S,A}(solver::MCTSSolver, mdp::MDP{S,A}, policy::MCTSPolicy{S,A}=MCTSPolicy{S,A}())
    fill_defaults!(policy, solver, mdp)
    return policy
end

# retuns an approximately optimal action
function POMDPs.action(policy::AbstractMCTSPolicy, state)
    n_iterations = policy.mcts.n_iterations
    depth = policy.mcts.depth
    # build the tree
    for n = 1:n_iterations
        simulate(policy, state, depth)
    end
    # find the index of action with highest q val
    best = best_sanode_Q(getnode(policy, state))
    # use map to conver index to mdp action
    return best.action
end

# runs a simulation from the passed in state to the specified depth
function simulate(policy::AbstractMCTSPolicy, state, depth::Int64)
    # model parameters
    mdp = policy.mdp
    discount_factor = discount(mdp) 
    rng = policy.mcts.rng

    # once depth is zero return
    if depth == 0 || isterminal(policy.mdp, state)
        return 0.0
    end

    # if unexplored state add to the tree and run rollout
    if !hasnode(policy, state)
        newnode = insert_node!(policy, state)
        return rollout(policy, state, depth) # TODO(?) upgrade this to some more flexible value estimate
    end 
    # if previously visited node
    snode = getnode(policy, state)

    # pick action using UCT
    snode.N += 1 # increase number of node visits by one
    sanode = best_sanode_UCB(snode, policy.mcts.exploration_constant)

    # transition to a new state
    sp, r = generate(mdp, state, sanode.action, rng)
    
    if policy.mcts.enable_tree_vis
        record_visit(policy, sanode, sp)
    end

    q = r + discount_factor * simulate(policy, sp, depth - 1)
    sanode.N += 1
    sanode.Q += ((q - sanode.Q) / (sanode.N)) # moving average of Q value
    return q
end

# recursive rollout to specified depth, returns the accumulated discounted reward
function rollout(policy::AbstractMCTSPolicy, s, d::Int)
    sim = policy.sim
    sim.max_steps = d 
    POMDPs.simulate(sim, policy.mdp, policy.rollout_policy, s)
end

# these functions are here so that they can be overridden by the aggregating solver
hasnode(policy::AbstractMCTSPolicy, s) = haskey(policy.tree, s)
function insert_node!(policy::AbstractMCTSPolicy, s)
    newnode = policy.tree[deepcopy(s)] = StateNode(policy.mdp, s)
    if policy.mcts.enable_tree_vis
        for sanode in newnode.sanodes
            sanode._vis_stats = Set()
        end
    end
    return newnode
end
getnode(policy::AbstractMCTSPolicy, s) = policy.tree[s]
record_visit(policy::AbstractMCTSPolicy, sanode::StateActionNode, s) = push!(sanode._vis_stats, s)

# returns the best action based on the Q score
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

# returns the best action based on the UCB score with exploration constant c
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
