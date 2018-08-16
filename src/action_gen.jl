"""
Generate a new action when the set of actions is widened.
"""
function next_action end

mutable struct RandomActionGenerator{RNG<:AbstractRNG}
    rng::RNG
end
RandomActionGenerator() = RandomActionGenerator(Random.GLOBAL_RNG)

function next_action(gen::RandomActionGenerator, mdp::Union{POMDP,MDP}, s, snode::AbstractStateNode)
    rand(gen.rng, actions(mdp, s))
end
next_action(f::Function, mdp::Union{POMDP,MDP}, s, snode::AbstractStateNode) = f(mdp, s, snode)
