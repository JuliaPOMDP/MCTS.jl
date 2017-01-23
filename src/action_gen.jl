"""
Generate a new action when the set of actions is widened.
"""
function next_action end

type RandomActionGenerator
    rng::AbstractRNG
    action_space::Nullable{Any} # should be Nullable{AbstractSpace}, but https://github.com/JuliaIO/JLD.jl/issues/106
    RandomActionGenerator(rng::AbstractRNG=MersenneTwister(), action_space=nothing) = new(rng, action_space==nothing ? Nullable{Any}(): Nullable{Any}(action_space))
end

function next_action{S,A}(gen::RandomActionGenerator, mdp::Union{POMDP,MDP}, s, snode::DPWStateNode{S,A})
    rand(gen.rng, actions(mdp, s))
end
next_action{S,A}(f::Function, mdp::Union{POMDP,MDP}, s, snode::DPWStateNode{S,A}) = f(mdp, s, snode)
