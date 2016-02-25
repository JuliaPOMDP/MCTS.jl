abstract Aggregator # assigns states of type S to aggregate states; should have assign() written for it

# assigns a ground state to an aggregate state
assign(ag::Aggregator, s) = error("no implementation of assign() for ag::$(typeof(ag)) for AgUCTSolver. Please implement this method to define how to aggregate states.")

# this simply aggregates states to themselves - for testing purposes
type NoAggregation <: Aggregator end
assign(ag::NoAggregation, s) = s

# handles statistics for an aggregated state
type AgNode
    N::Array{Int64,1} # number of visits at the node for each action
    Q::Array{Reward,1} # estimated value for each action
    AgNode(nA) = new(zeros(Int32,nA),zeros(Reward,nA)) # simplified cosntructor
end

# AgUCT solver type
type AgUCTSolver <: POMDPs.Solver
	n_iterations::Int64	# number of iterations during each action() call
	depth::Int64 # the max depth of the tree
	exploration_constant::Float64 # constant balancing exploration and exploitation
    aggregator::Aggregator
    rng::AbstractRNG # random number generator
    rollout_solver::Union{Solver,Policy} # rollout policy
                                         # if this is a Solver, solve() will be called when solve() is called on the AgUCTSolver;
                                         # if this is a Policy, it will be used directly
end
# solver constructor
function AgUCTSolver(;n_iterations::Int64 = 100, 
                     depth::Int64 = 10,
                     exploration_constant::Float64 = 1.0,
                     rng = MersenneTwister(),
                     aggregator = NoAggregation(),
                     rollout_solver = RandomSolver(rng)) # random policy is default
    return AgUCTSolver(n_iterations, depth, exploration_constant, aggregator, rng, rollout_solver)
end

type AgUCTPolicy <: POMDPs.Policy
	mcts::AgUCTSolver # containts the solver parameters
	mdp::POMDP # model
    rollout_policy::Policy # rollout policy
    tree::Dict{Any, AgNode} # maps aggregate states to corresponding nodes
    action_map::Vector{Action} # for converting action idxs to action types
    action_space::AbstractSpace # pre-allocated for rollout
    state::State # pre-allocated for sampling
    action::Action # pre-allocated for sampling
    distribution::AbstractDistribution # pre-allocated for memory efficiency
    sim::MDPRolloutSimulator # for doing rollouts

    AgUCTPolicy()=new() # is it too dangerous to have this?
end
# policy constructor
function AgUCTPolicy(mcts::AgUCTSolver, mdp::POMDP)
    p = AgUCTPolicy()
    fill_defaults!(p, mcts, mdp)
    p
end
# sets members to suitable default values (broken out of the constructor so that it can be used elsewhere)
function fill_defaults!(p::AgUCTPolicy, solver::AgUCTSolver=p.mcts, mdp::POMDP=p.mdp)
    p.mcts = solver
    p.mdp = mdp
    if isa(p.mcts.rollout_solver, Solver)
        p.rollout_policy = solve(p.mcts.rollout_solver, mdp)
    else
        p.rollout_policy = p.mcts.rollout_solver
    end

    # creates the action map
    am = Action[]
    space = actions(mdp)
    for a in iterator(space)
        push!(am, a)
    end
    p.action_map = am

    # pre-allocate
    p.tree = Dict{Any, AgNode}()
    p.action_space = actions(mdp)
    p.distribution = create_transition_distribution(mdp)
    p.state = create_state(mdp)
    p.action = create_action(mdp)
    p.sim = MDPRolloutSimulator(rng=solver.rng, max_steps=0)
    return p
end

# no computation is done in solve - the solver is just given the mdp model that it will work with
function POMDPs.solve(solver::AgUCTSolver, mdp::POMDP, policy::AgUCTPolicy=AgUCTPolicy())
    fill_defaults!(policy, solver, mdp)
    return policy
end

# retuns an approximately optimal action
function POMDPs.action(policy::AgUCTPolicy, state::State)
    n_iterations = policy.mcts.n_iterations
    depth = policy.mcts.depth
    # build the tree
    for n = 1:n_iterations
        simulate(policy, state, depth)
    end
    # find the index of action with highest q val
    agstate = assign(policy.mcts.aggregator, state)
    i = indmax(policy.tree[agstate].Q)
    # use map to convert index to mdp action
    return policy.action_map[i]
end

# runs a simulation from the passed in state to the specified depth
function simulate(policy::AgUCTPolicy, state::State, depth::Int64)
    # model parameters
    mdp = policy.mdp
    na = n_actions(mdp)
    discount_factor = discount(mdp) 
    sp = policy.state
    rng = policy.mcts.rng

    # solver parameters
    n_iterations = policy.mcts.n_iterations
    tree = policy.tree
    ec = policy.mcts.exploration_constant

    # once depth is zero return
    if depth == 0
        return 0.0
    end

    agstate = assign(policy.mcts.aggregator, state)

    # if unexplored state add to the tree and run rollout
    if !haskey(tree, agstate)
        tree[deepcopy(agstate)] = AgNode(na)
        return rollout(policy, state, depth) # TODO(?) upgrade this to some more flexible value estimate
    end 
    # if previously visited node
    agnode = tree[agstate]
    # pick action using UCT
    i = indmax(agnode.Q + ec * real(sqrt(complex(log(sum(agnode.N))./agnode.N)))) 
    a = policy.action_map[i]
    # transition to a new state
    d = policy.distribution
    d = transition(mdp, state, a, d)
    sp = rand(rng, d, sp)
    # update the Q and n values
    r = reward(mdp, state, a, sp)
    q = r + discount_factor * simulate(policy, sp, depth - 1)
    agnode.N[i] += 1 # increase number of node visits by one
    agnode.Q[i] += ((q - agnode.Q[i]) / (agnode.N[i])) # moving average of Q value
    return q
end

# recursive rollout to specified depth, returns the accumulated discounted reward
function rollout(policy::AgUCTPolicy, s::State, d::Int)
    sim = policy.sim
    sim.max_steps = d 
    POMDPs.simulate(sim, policy.mdp, policy.rollout_policy, s)
end
