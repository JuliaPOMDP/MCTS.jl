# this class should implement next_action 
abstract ActionGenerator

type RandomActionGenerator <: ActionGenerator
    rng::AbstractRNG
    action_space::Nullable{Any} # should be Nullable{AbstractSpace}, but https://github.com/JuliaIO/JLD.jl/issues/106
    RandomActionGenerator(rng::AbstractRNG=MersenneTwister(), action_space=nothing) = new(rng, action_space==nothing ? Nullable{Any}(): Nullable{Any}(action_space))
end

# type and constructor for the dpw solver
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
    action_generator::ActionGenerator
end

# constructor
function DPWSolver(;depth::Int=10,
                    exploration_constant::Float64=1.0,
                    n_iterations::Int=100,
                    k_action::Float64=10.0,
                    alpha_action::Float64=0.5,
                    k_state::Float64=10.0,
                    alpha_state::Float64=0.5,
                    rng::AbstractRNG=MersenneTwister(),
                    rollout_solver::Union{Policy,Solver}=RandomSolver(rng),
                    action_generator::ActionGenerator=RandomActionGenerator(rng))
    DPWSolver(depth, exploration_constant, n_iterations, k_action, alpha_action, k_state, alpha_state, rng, rollout_solver,action_generator)
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
    DPWStateActionNode() = new(Dict{S,StateActionStateNode}(),0,0)
end

type DPWStateNode{S,A}
    A::Dict{A,DPWStateActionNode{S}}
    N::Int
    DPWStateNode() = new(Dict{A,DPWStateActionNode{S}}(),0)
end

type DPWPolicy{S,A} <: AbstractMCTSPolicy{S}
    solver::DPWSolver
    mdp::Union{POMDP{S,A},MDP{S,A}}
    tree::Dict{S,DPWStateNode{S,A}} 
    rollout_policy::Policy
end

DPWPolicy{S,A}(solver::DPWSolver,
               mdp::Union{POMDP{S,A},MDP{S,A}}) = DPWPolicy{S,A}(solver,
                                               mdp,
                                               Dict{S,DPWStateNode{S,A}}(),
                                               RandomPolicy(mdp, rng=solver.rng))

