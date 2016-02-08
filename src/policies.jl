type RandomPolicy <: Policy
    mdp::POMDP # contains the model
    rng::AbstractRNG
    action_space::AbstractSpace
end
# constructor
function RandomPolicy(mdp::POMDP, rng::AbstractRNG=MersenneTwister())
    as = actions(mdp)
    return RandomPolicy(mdp, rng, as)
end

function POMDPs.action(policy::RandomPolicy, state::State, a::Action=create_action(policy.mdp))
    action_space = actions(policy.mdp, state, policy.action_space)
    return rand(policy.rng, policy.action_space, a)
end

type RandomSolver <: Solver
    rng::AbstractRNG
end

function POMDPs.solve(solver::RandomSolver, mdp::POMDP)
    return RandomPolicy(mdp, solver.rng)
end
