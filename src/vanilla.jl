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
    rollout_solver::Union{Solver,Policy} # rollout policy
                                         # if this is a Solver, solve() will be called when solve() is called on the MCTSSolver;
                                         # if this is a Policy, it will be used directly
end
# solver constructor
function MCTSSolver(;n_iterations::Int64 = 100, 
                     depth::Int64 = 10,
                     exploration_constant::Float64 = 1.0,
                     rng = MersenneTwister(),
                     rollout_solver = RandomSolver(rng)) # random policy is default
    return MCTSSolver(n_iterations, depth, exploration_constant, rng, rollout_solver)
end

# MCTS policy type
type MCTSPolicy <: POMDPs.Policy
	mcts::MCTSSolver # containts the solver parameters
	mdp::POMDP # model
    rollout_policy::Policy # rollout policy
    tree::Dict{State, StateNode} # the search tree
    action_map::Vector{Action} # for converting action idxs to action types
    action_space::AbstractSpace # pre-allocated for rollout
    state::State # pre-allocated for sampling
    action::Action # pre-allocated for sampling
    distribution::AbstractDistribution # pre-allocated for memory efficiency
    sim::MDPRolloutSimulator # for doing rollouts

    MCTSPolicy()=new() # is it too dangerous to have this?
end
# policy constructor
function MCTSPolicy(mcts::MCTSSolver, mdp::POMDP)
    p = MCTSPolicy()
    fill_defaults!(p, mcts, mdp)
    p
end
# sets members to suitable default values (broken out of the constructor so that it can be used elsewhere)
function fill_defaults!(p::MCTSPolicy, solver::MCTSSolver=p.mcts, mdp::POMDP=p.mdp)
    p.mcts = solver
    p.mdp = mdp
    if isa(p.mcts.rollout_solver, Solver)
        p.rollout_policy = solve(p.mcts.rollout_solver, mdp)
    else
        p.rollout_policy = p.mcts.rollout_policy
    end

    # creates the action map
    am = Action[]
    space = actions(mdp)
    for a in iterator(space)
        push!(am, a)
    end
    p.action_map = am

    # pre-allocate
    p.tree = Dict{State, StateNode}()
    p.action_space = actions(mdp)
    p.distribution = create_transition_distribution(mdp)
    p.state = create_state(mdp)
    p.action = create_action(mdp)
    p.sim = MDPRolloutSimulator(rng=solver.rng, max_steps=0)
    return p
end

# no computation is done in solve - the solver is just given the mdp model that it will work with
function POMDPs.solve(solver::MCTSSolver, mdp::POMDP, policy::MCTSPolicy=MCTSPolicy())
    fill_defaults!(policy, solver, mdp)
    return policy
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
    i = indmax(policy.tree[state].Q)
    # use map to conver index to mdp action
    return policy.action_map[i]
end

# runs a simulation from the passed in state to the specified depth
function simulate(policy::MCTSPolicy, state::State, depth::Int64)
    # model parameters
    mdp = policy.mdp
    na = n_actions(mdp)
    discount_factor = discount(mdp) 
    sp = policy.state
    rng = policy.mcts.rng

    # solver parameters
    n_iterations = policy.mcts.n_iterations
    tree = policy.tree
    exploration_constant = policy.mcts.exploration_constant

    # once depth is zero return
    if depth == 0
        return 0.0
    end

    # if unexplored state add to the tree and run rollout
    if !haskey(tree, state)
        tree[deepcopy(state)] = StateNode(na)
        return rollout(policy, state, depth) # TODO(?) upgrade this to some more flexible value estimate
    end 
    # if previously visited node
    snode = tree[state]
    # pick action using UCT
    i = indmax(snode.Q + exploration_constant * real(sqrt(complex(log(sum(snode.n))./snode.n)))) 
    a = policy.action_map[i]
    # transition to a new state
    d = policy.distribution
    d = transition(mdp, state, a, d)
    sp = rand(rng, d, sp)
    # update the Q and n values
    r = reward(mdp, state, a, sp)
    q = r + discount_factor * simulate(policy, sp, depth - 1)
    snode.n[i] += 1 # increase number of node visits by one
    snode.Q[i] += ((q - snode.Q[i]) / (snode.n[i])) # moving average of Q value
    return q
end

# recursive rollout to specified depth, returns the accumulated discounted reward
function rollout(policy::MCTSPolicy, s::State, d::Int)
    sim = policy.sim
    sim.max_steps = d 
    POMDPs.simulate(sim, policy.mdp, policy.rollout_policy, s)
end
