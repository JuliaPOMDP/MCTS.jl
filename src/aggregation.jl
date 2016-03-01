abstract Aggregator # assigns states of type S to aggregate states; should have assign() written for it

# assigns a ground state to an aggregate state
assign(ag::Aggregator, s) = error("no implementation of assign() for ag::$(typeof(ag)) for AgUCTSolver. Please implement this method to define how to aggregate states.")
# gives the aggregator information about the mdp at the beginning will be called within solve(::AgUCTSolver, ::POMDP)
function initialize!(ag::Aggregator, mdp::POMDP) end # do nothing by default

# this simply aggregates states to themselves - for testing purposes
type NoAggregation <: Aggregator end
assign(ag::NoAggregation, s) = s

# handles statistics for an aggregated state
type AgNode
    N::Int # number of visits at the node for each action
    sanodes::Vector{StateActionNode} # all of the actions and their statistics
end
function AgNode(mdp::POMDP, agstate)
    ns = StateActionNode[StateActionNode(a, 0, 0.0) for a in iterator(actions(mdp, agstate))]
    return AgNode(0, ns)
end

# AgUCT solver type
type AgUCTSolver <: AbstractMCTSSolver
	n_iterations::Int64	# number of iterations during each action() call
	depth::Int64 # the max depth of the tree
	exploration_constant::Float64 # constant balancing exploration and exploitation
    aggregator::Aggregator
    rng::AbstractRNG # random number generator
    rollout_solver::Union{Solver,Policy} # rollout policy
                                         # if this is a Solver, solve() will be called when solve() is called on the AgUCTSolver;
                                         # if this is a Policy, it will be used directly
    enable_tree_vis::Bool
end
# solver constructor
function AgUCTSolver(;n_iterations::Int64 = 100, 
                     depth::Int64 = 10,
                     exploration_constant::Float64 = 1.0,
                     rng = MersenneTwister(),
                     aggregator = NoAggregation(),
                     rollout_solver = RandomSolver(rng), # random policy is default
                     enable_tree_vis::Bool = false)
    return AgUCTSolver(n_iterations, depth, exploration_constant, aggregator, rng, rollout_solver, enable_tree_vis)
end

type AgUCTPolicy <: AbstractMCTSPolicy
	mcts::AgUCTSolver # containts the solver parameters
	mdp::POMDP # model
    rollout_policy::Policy # rollout policy
    tree::Dict{Any, AgNode} # maps aggregate states to corresponding nodes
    sim::MDPRolloutSimulator # for doing rollouts
    aggregator::Aggregator # a copy of the aggregator in the solver (a copy is necessary because the aggregator might mutate)

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

    p.aggregator = deepcopy(p.mcts.aggregator)
    initialize!(p.aggregator, mdp)

    # pre-allocate
    p.tree = Dict{Any, AgNode}()
    p.sim = MDPRolloutSimulator(rng=solver.rng, max_steps=0)
    return p
end

# no computation is done in solve - the solver is just given the mdp model that it will work with
function POMDPs.solve(solver::AgUCTSolver, mdp::POMDP, policy::AgUCTPolicy=AgUCTPolicy())
    fill_defaults!(policy, solver, mdp)
    return policy
end

function hasnode(policy::AgUCTPolicy, s::State)
    agstate = assign(policy.mcts.aggregator, s)
    return haskey(policy.tree, agstate)
end

function insert_node!(policy::AgUCTPolicy, s::State)
    agstate = assign(policy.mcts.aggregator, s)
    newnode = policy.tree[agstate] = AgNode(policy.mdp, agstate) # 
    if policy.mcts.enable_tree_vis
        for sanode in newnode.sanodes
            sanode._vis_stats = Set()
        end
    end
    return newnode
end

function getnode(policy::AgUCTPolicy, s::State)
    agstate = assign(policy.mcts.aggregator, s)
    return policy.tree[agstate]
end

function record_visit(policy::AgUCTPolicy, sanode::StateActionNode, s)
    push!(sanode._vis_stats, assign(policy.mcts.aggregator, s))
end
