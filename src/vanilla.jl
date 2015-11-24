# State node in the search tree
type StateNode
    n::Array{Int64,1} # number of visits at the node for each action
    Q::Array{Reward,1} # estimated value for each action
    StateNode(nA) = new(zeros(Int32,nA),zeros(Reward,nA)) # simplified cosntructor
end

# MCTS solver type
type MCTSSolver <: POMDPs.Solver
	n_iterations::Int64	# number of iterations during each action() call
	depth::Int64 # the max depth of the tree
	exploration_constant::Float64 # constant balancing exploration and exploitation
    rng::AbstractRNG # random number generator
    tree::Dict{State, StateNode} # the search tree
end
# solver constructor
function MCTSSolver(;n_iterations::Int64 = 50, 
                      depth::Int64 = 20,
                      exploration_constant::Float64 = 3.0,
                      rng = MersenneTwister(1))
    tree = Dict{State, StateNode}()
    return MCTSSolver(n_iterations, depth, exploration_constant, rng, tree)
end

# MCTS policy type
type MCTSPolicy <: POMDPs.Policy
	mcts::MCTSSolver # containts the solver parameters
	mdp::POMDP # model
    action_map::Vector{Action} # for converting action idxs to action types
    action_space::AbstractSpace # pre-allocated for rollout
    state::State # pre-allocated for sampling
    action::Action # pre-allocated for sampling
    distribution::AbstractDistribution # pre-allocated for memory efficiency
    rollout_policy::Policy # used in the rollout evaluation
end
# policy constructor
function MCTSPolicy(mcts::MCTSSolver, mdp::POMDP, 
                    rollout_policy=RandomPolicy(mdp, mcts.rng)) # random policy is default
    # creates the action map
    am = Action[]
    space = actions(mdp)
    for a in domain(space)
        push!(am, a)
    end
    # pre-allocate action space
    as = actions(mdp)
    # pre-allocate the state distrbution
    d = create_transition_distribution(mdp)
    s = create_state(mdp)
    a = create_action(mdp)
    return MCTSPolicy(mcts, mdp, am, as, s, a, d, rollout_policy)
end

# for convenience - no computation is done in solve
function POMDPs.solve(solver::MCTSSolver, mdp::POMDP, policy::MCTSPolicy)
    policy
end

# retuns an approximately optimal action
function POMDPs.action(policy::MCTSPolicy, state::State)
    n_iterations = policy.mcts.n_iterations
    depth = policy.mcts.depth
    # build the tree
    for n = 1:n_iterations
        simulate(policy, state, depth)
    end
    # find the index of action with highest q val
    i = indmax(policy.mcts.tree[state].Q)
    # use map to conver index to mdp action
    return policy.action_map[i]
end

# runs a simulation from the passed in state to the specified depth
function POMDPs.simulate(policy::MCTSPolicy, state::State, depth::Int64)
    # model parameters
    mdp = policy.mdp
    na = n_actions(mdp)
    discount_factor = discount(mdp) 
    sp = policy.state
    rng = policy.mcts.rng

    # solver parameters
    n_iterations = policy.mcts.n_iterations
    tree = policy.mcts.tree
    exploration_constant = policy.mcts.exploration_constant

    # once depth is zero return
    if depth == 0
        return 0.0
    end

    # if unexplored state add to the tree and run rollout
    if !haskey(tree, state)
        tree[deepcopy(state)] = StateNode(na)
        return rollout(policy, depth, state)
    end 
    # if previously visited node
    snode = tree[state]
    # pick action using UCT
    i = indmax(snode.Q + exploration_constant * real(sqrt(complex(log(sum(snode.n))./snode.n)))) 
    a = policy.action_map[i]
    # transition to a new state
    d = policy.distribution
    d = transition(mdp, state, a, d)
    sp = rand!(rng, sp, d)
    # update the Q and n values
    r = reward(mdp, state, a)
    q = r + discount_factor * simulate(policy, sp, depth - 1)
    snode.n[i] += 1 # increase number of node visits by one
    snode.Q[i] += ((q - snode.Q[i]) / (snode.n[i])) # moving average of Q value
    return q
end

# recursive rollout to specified depth, returns the accumulated discounted reward
function rollout(policy::MCTSPolicy, depth::Int64, state::State)
    mdp = policy.mdp
    # finish when depth is zero or reach terminal state
    if depth == 0 || isterminal(mdp, state)
        return 0.0
    end
    d = policy.distribution
    discount_factor = discount(mdp) 
    rng = policy.mcts.rng
    sp = policy.state
    # follow the rollout policy 
    a = action(policy.rollout_policy, state)
    # sample the next state
    transition(mdp, state, a, d)
    sp = rand!(rng, sp, d)
    # compute reward
    r = reward(mdp, state, a)
    return r + discount_factor * rollout(policy, depth - 1, sp)
end 

