# type and constructor for the dpw solver

type DPWSolver <: Solver
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
                    rollout_solver::Union{Policy,Solver}=RandomSolver(rng))
    DPWSolver(depth, exploration_constant, n_iterations, k_action, alpha_action, k_state, alpha_state, rng, rollout_solver)
end

