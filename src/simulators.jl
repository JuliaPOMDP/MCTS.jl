# TODO get rid of this when GenerativeModels.jl is up
# XXX this is inefficient because it allocates a new transition every time
function generate{S,A}(mdp::MDP{S,A}, s::S, a::A, rng::AbstractRNG)
    td = transition(mdp, s, a)
    sp = S()
    sp = rand(rng, td, sp)
    r = reward(mdp, s, a, sp)
    return (sp, r)
end
