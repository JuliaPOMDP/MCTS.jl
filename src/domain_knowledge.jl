"""
    estimate_value(policy, state, depth)

Return an estimate of the value.

"""
POMDPs.@pomdp_func estimate_value(estimator::Any, mdp::Union{POMDP,MDP}, state, depth::Int)
estimate_value(f::Function, mdp::Union{POMDP,MDP}, state, depth::Int) = f(mdp, state, depth)
function estimate_value(estimator::Number, mdp::Union{POMDP,MDP}, state, depth::Int)
    return convert(Float64, estimator)
end

"""
RolloutEstimate

If this is passed to the estimate_value field of the solver, rollouts will be used to estimate the value at the leaf nodes

Fields:
    solver::Union{Solver,Policy,Function}
        If this is a Solver, solve(solver, mdp) will be called to find the rollout policy
        If this is a Policy, the policy will be used for rollouts
        If this is a Function, a POMDPToolbox.FunctionPolicy with this function will be used for rollouts
"""
type RolloutEstimate
    solver::Union{Solver,Policy,Function} # rollout policy or solver
end

"""
SolvedRolloutEstimate

This is within the policy when a RolloutEstimate is passed to an AbstractMCTSSolver
"""
type SolvedRolloutEstimate
    policy::Policy
    rng::AbstractRNG
end

estimate_value(estimator::SolvedRolloutEstimate, mdp::MDP, state, depth::Int) = rollout(estimator, mdp, state, depth)

function rollout(estimator::SolvedRolloutEstimate, mdp::MDP, s, d::Int)
    sim = RolloutSimulator(rng=estimator.rng, max_steps=d)
    POMDPs.simulate(sim, mdp, p, s)
end

"""
    init_Q(initializer, mdp, s, a)

Return a value to initialize Q(s,a) to based on domain knowledge.

By default, returns 0.0.
"""
POMDPs.@pomdp_func init_Q(initializer::Any, mdp::Union{MDP,POMDP}, s, a)
init_Q(f::Function, mdp::Union{MDP,POMDP}, s, a) = f(mdp, s, a)
init_Q(n::Number, mdp::Union{MDP,POMDP}, s, a) = convert(Float64, n)

"""
    init_N(initializer, mdp, s, a)

Return a value to initialize N(s,a) to based on domain knowledge.

By default, returns 0.
"""
POMDPs.@pomdp_func init_N(initializer::Any, mdp::Union{MDP,POMDP}, s, a)
init_N(f::Function, mdp::Union{MDP,POMDP}, s, a) = f(mdp, s, a)
init_N(n::Number, mdp::Union{MDP,POMDP}, s, a) = convert(Int, n)
