"""
    estimate_value(estimator, mdp, state)

Return an estimate of the value.

"""
function estimate_value end
estimate_value(f::Function, mdp::Union{POMDP,MDP}, state) = f(mdp, state)
estimate_value(estimator::Number, mdp::Union{POMDP,MDP}, state) = convert(Float64, estimator)

"""
RolloutEstimator

If this is passed to the estimate_value field of the solver, rollouts will be used to estimate the value at the leaf nodes

Fields:
    solver::Union{Solver,Policy,Function}
        If this is a Solver, solve(solver, mdp) will be called to find the rollout policy
        If this is a Policy, the policy will be used for rollouts
        If this is a Function, a POMDPToolbox.FunctionPolicy with this function will be used for rollouts
"""
mutable struct RolloutEstimator
    solver::Union{Solver,Policy,Function} # rollout policy or solver
end

"""
SolvedRolloutEstimator

This is within the policy when a RolloutEstimator is passed to an AbstractMCTSSolver
"""
mutable struct SolvedRolloutEstimator{P<:Policy, RNG<:AbstractRNG}
    policy::P
    rng::RNG
    depth::Union{Int, Nothing}

    function SolvedRolloutEstimator(policy, rng, depth::Union{Int, Nothing}=nothing)
        new{typeof(policy), typeof(rng)}(policy, rng, depth)
    end
end

convert_estimator(ev, solver, mdp) = ev
function convert_estimator(ev::RolloutEstimator, solver::AbstractMCTSSolver, mdp::Union{POMDP,MDP})
    return SolvedRolloutEstimator(convert_to_policy(ev.solver, mdp), solver.rng)
end
convert_to_policy(p::Policy, mdp::Union{POMDP,MDP}) = p
convert_to_policy(s::Solver, mdp::Union{POMDP,MDP}) = solve(s, mdp)
convert_to_policy(f::Function, mdp::Union{POMDP,MDP}) = FunctionPolicy(f)


@POMDP_require estimate_value(estimator::SolvedRolloutEstimator, mdp::MDP, state) begin
    @subreq rollout(estimator, mdp, state)
end

estimate_value(estimator::SolvedRolloutEstimator, mdp::MDP, state) = rollout(estimator, mdp, state)

# this rollout function is really just here in case people search for rollout
function rollout(estimator::SolvedRolloutEstimator, mdp::MDP, s)
    sim = RolloutSimulator(rng=estimator.rng, max_steps=estimator.depth)
    POMDPs.simulate(sim, mdp, estimator.policy, s)
end

@POMDP_require rollout(estimator::SolvedRolloutEstimator, mdp::MDP, s) begin
    sim = RolloutSimulator(rng=estimator.rng, max_steps=estimator.depth)
    @subreq POMDPs.simulate(sim, mdp, estimator.policy, s)
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
