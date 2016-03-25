# TODO get rid of this when GenerativeModels.jl is up
# XXX this is inefficient because it allocates a new transition every time
function generate(mdp::POMDP, s::State, a::Action, rng::AbstractRNG)
    td = transition(mdp, s, a)
    sp = create_state(mdp)
    sp = rand(rng, td, sp)
    r = reward(mdp, s, a, sp)
    return (sp, r)
end
