type MDPRolloutSimulator <: Simulator
    rng::AbstractRNG
    max_steps::Int
    eps::Float64
end
MDPRolloutSimulator(;rng::AbstractRNG=MersenneTwister(),
                     max_steps::Int=typemax(Int),
                     eps::Float64=0.0) = MDPRolloutSimulator(rng, max_steps, eps)

# TODO make this efficient by preallocating, etc.
function POMDPs.simulate(sim::MDPRolloutSimulator, mdp::POMDP, policy::Policy, initial_state::State)
    s = initial_state
    rew = 0.0
    disc = 1.0
    step = 1
    while disc > sim.eps && !isterminal(mdp, s) && step <= sim.max_steps
        a = action(policy, s)
        s, r = generate(mdp, s, a, sim.rng)
        rew += disc*r
        disc *= discount(mdp)
        step += 1
    end
    return rew
end

# TODO get rid of this when GenerativeModels.jl is up
# XXX this is inefficient because it allocates a new transition every time
function generate(mdp::POMDP, s::State, a::Action, rng::AbstractRNG)
    td = transition(mdp, s, a)
    sp = create_state(mdp)
    sp = rand(rng, td, sp)
    r = reward(mdp, s, a, sp)
    return (sp, r)
end
