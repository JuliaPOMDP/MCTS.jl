"""
Generate a new action when the set of actions is widened.
"""
function next_action end

mutable struct RandomActionGenerator{RNG<:AbstractRNG}
    rng::RNG
end
RandomActionGenerator() = RandomActionGenerator(Base.GLOBAL_RNG)

function next_action{S,A}(gen::RandomActionGenerator, mdp::Union{POMDP,MDP}, s, snode::DPWStateNode{S,A})
    rand(gen.rng, actions(mdp, s))
end
next_action{S,A}(f::Function, mdp::Union{POMDP,MDP}, s, snode::DPWStateNode{S,A}) = f(mdp, s, snode)
