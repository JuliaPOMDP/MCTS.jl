# this class should implement next_action 
abstract ActionGenerator

type RandomActionGenerator <: ActionGenerator
    rng::AbstractRNG
    action_space::Nullable{Any} # should be Nullable{AbstractSpace}, but https://github.com/JuliaIO/JLD.jl/issues/106
    RandomActionGenerator(rng::AbstractRNG=MersenneTwister(), action_space=nothing) = new(rng, action_space==nothing ? Nullable{Any}(): Nullable{Any}(action_space))
end


"""
MCTS solver with DPW

Fields:

    depth::Int64:
        Maximum rollout horizon and tree depth.
        default: 10

    exploration_constant::Float64: 
        Specified how much the solver should explore.
        In the UCB equation, Q + c*sqrt(log(t/N)), c is the exploration constant.
        default: 1.0

    n_iterations::Int64
        Number of iterations during each action() call.
        default: 100

    rng::AbstractRNG:
        Random number generator

    k_action::Float64
    alpha_action::Float64
    k_state::Float64
    alpha_state::Float64
        These constants control the double progressive widening. A new state
        or action will be added if the number of children is less than or equal to kN^alpha.
        defaults: k:10, alpha:0.5

    rng::AbstractRNG:
        Random number generator

    rollout_solver::Union{Solver,Policy}:
        Rollout policy or solver.
        If this is a Policy, it will be used directly in rollouts;
        If it is a Solver, solve() will be called when solve() is called on the MCTSSolver.
        default: RandomSolver(rng)

    prior_knowledge::Any:
        An object containing any prior knowledge. Implement estimate_value, init_N, and init_Q to use this.
        default: nothing

    action_generator::ActionGenerator:
        Determines which new action should be added in progressive widening.
        default:RandomActionGenerator(rng)
"""
type DPWSolver <: AbstractMCTSSolver
    depth::Int                       # search depth
    exploration_constant::Float64    # exploration constant- governs trade-off between exploration and exploitation in MCTS
    n_iterations::Int                # number of iterations
    k_action::Float64                # first constant controlling action generation
    alpha_action::Float64            # second constant controlling action generation
    k_state::Float64                 # first constant controlling transition state generation
    alpha_state::Float64             # second constant controlling transition state generation
    rng::AbstractRNG
    rollout_solver::Union{Policy,Solver} # if this is a Solver, solve() will be called to get the rollout policy
                                         # if this is a Policy, it will be used for rollouts directly
    prior_knowledge::Any             # a custom object that encodes any prior knowledge about the problem - to be used in init_N, init_Q, and estimate_value
    action_generator::ActionGenerator
end

"""
    DPWSolver()

Use keyword arguments to specify values for the fields
"""
function DPWSolver(;depth::Int=10,
                    exploration_constant::Float64=1.0,
                    n_iterations::Int=100,
                    k_action::Float64=10.0,
                    alpha_action::Float64=0.5,
                    k_state::Float64=10.0,
                    alpha_state::Float64=0.5,
                    rng::AbstractRNG=MersenneTwister(),
                    rollout_solver::Union{Policy,Solver}=RandomSolver(rng),
                    prior_knowledge=nothing,
                    action_generator::ActionGenerator=RandomActionGenerator(rng))
    DPWSolver(depth, exploration_constant, n_iterations, k_action, alpha_action, k_state, alpha_state, rng, rollout_solver, prior_knowledge, action_generator)
end

type StateActionStateNode
    N::Int
    R::Float64
    StateActionStateNode() = new(0,0)
end

type DPWStateActionNode{S}
    V::Dict{S,StateActionStateNode}
    N::Int
    Q::Float64
    DPWStateActionNode(N,Q) = new(Dict{S,StateActionStateNode}(), N, Q)
end

type DPWStateNode{S,A}
    A::Dict{A,DPWStateActionNode{S}}
    N::Int
    DPWStateNode() = new(Dict{A,DPWStateActionNode{S}}(),0)
end

type DPWPolicy{S,A,PriorKnowledgeType} <: AbstractMCTSPolicy{S,A,PriorKnowledgeType}
    solver::DPWSolver
    mdp::Union{POMDP{S,A},MDP{S,A}}
    tree::Dict{S,DPWStateNode{S,A}} 
    rollout_policy::Policy
end

function DPWPolicy{S,A}(solver::DPWSolver, mdp::Union{POMDP{S,A},MDP{S,A}})
    return DPWPolicy{S,A,typeof(solver.prior_knowledge)}(solver,
                                   mdp,
                                   Dict{S,DPWStateNode{S,A}}(),
                                   RandomPolicy(mdp, rng=solver.rng))
end
