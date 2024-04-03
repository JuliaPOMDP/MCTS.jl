"""
    estimate_value(estimator, mdp, state, remaining_depth)

Return an estimate of the value.

The `remaining_depth` argument indicates the remaining number of steps from the point where `estimate_value` is called to the `depth` argument of the MCTS solver. It can be safely ignored, but can be used to limit rollouts to a fixed horizon from the *root node*.
"""
function estimate_value end
estimate_value(f::Function, mdp::Union{POMDP,MDP}, state, remaining_depth) = f(mdp, state, remaining_depth)
estimate_value(estimator::Number, mdp::Union{POMDP,MDP}, state, remaining_depth) = convert(Float64, estimator)

"""
RolloutEstimator

If this is passed to the estimate_value field of the solver, rollouts will be used to estimate the value at the leaf nodes

Fields:
    solver::Union{Solver,Policy,Function}
        If this is a Solver, solve(solver, mdp) will be called to find the rollout policy
        If this is a Policy, the policy will be used for rollouts
        If this is a Function, a POMDPToolbox.FunctionPolicy with this function will be used for rollouts
    max_depth::Int (default 50)
        Rollout depth. If this is -1, it will roll out to the `depth` argument of the `MCTSSolver` from the root node.
    eps::Float64 (default 0.0)
        A small number; if γᵗ where γ is the discount factor and t is the time step becomes smaller than this, the rollout will be terminated.
"""
struct RolloutEstimator
    solver::Union{Solver,Policy,Function} # rollout policy or solver
    max_depth::Int
    eps::Float64

    function RolloutEstimator(solver::Union{Solver,Policy,Function};
                              max_depth::Int=50,
                              eps::Float64=0.0)
        new(solver, max_depth, eps)
    end
end

"""
SolvedRolloutEstimator

This is within the policy when a RolloutEstimator is passed to an AbstractMCTSSolver
"""
mutable struct SolvedRolloutEstimator{P<:Policy, RNG<:AbstractRNG}
    policy::P
    rng::RNG
    max_depth::Int
    eps::Float64
end

convert_estimator(ev, solver, mdp) = ev
function convert_estimator(ev::RolloutEstimator, solver::AbstractMCTSSolver, mdp::Union{POMDP,MDP})
    return SolvedRolloutEstimator(convert_to_policy(ev.solver, mdp), solver.rng, ev.max_depth, ev.eps)
end
convert_to_policy(p::Policy, mdp::Union{POMDP,MDP}) = p
convert_to_policy(s::Solver, mdp::Union{POMDP,MDP}) = solve(s, mdp)
convert_to_policy(f::Function, mdp::Union{POMDP,MDP}) = FunctionPolicy(f)

@POMDP_require estimate_value(estimator::SolvedRolloutEstimator, mdp::MDP, state, remaining_depth) begin
    sim = RolloutSimulator(rng=estimator.rng, max_steps=estimator.max_depth, eps=estimator.eps)
    @subreq POMDPs.simulate(sim, mdp, estimator.policy, s)
end

# rollouts occur here
function estimate_value(estimator::SolvedRolloutEstimator, mdp::MDP, state, remaining_depth)
    if estimator.max_depth == -1
        max_steps = remaining_depth
    else
        max_steps = estimator.max_depth
    end
    sim = RolloutSimulator(rng=estimator.rng, max_steps=max_steps, eps=estimator.eps)
    return POMDPs.simulate(sim, mdp, estimator.policy, state)
end

"""
    init_Q(initializer, mdp, s, a)

Return a value to initialize Q(s,a) to based on domain knowledge.
"""
function init_Q end
init_Q(f::Function, mdp::Union{MDP,POMDP}, s, a) = f(mdp, s, a)
init_Q(n::Number, mdp::Union{MDP,POMDP}, s, a) = convert(Float64, n)

"""
    init_N(initializer, mdp, s, a)

Return a value to initialize N(s,a) to based on domain knowledge.
"""
function init_N end
init_N(f::Function, mdp::Union{MDP,POMDP}, s, a) = f(mdp, s, a)
init_N(n::Number, mdp::Union{MDP,POMDP}, s, a) = convert(Int, n)
