"""
    estimate_value(policy, state, depth)

Return an estimate of the value.

Implement this for you custom prior knowledge type to provide a value estimate based on prior knowledge.
By default, this runs a rollout simulation with the rollout policy.
"""
function estimate_value{S,A,PriorKnowledgeType}(policy::AbstractMCTSPolicy{S,A,PriorKnowledgeType}, state::S, depth)
    rollout(policy, state, depth)
end

function rollout(p::AbstractMCTSPolicy, s, d::Int)
    sim = RolloutSimulator(rng=dpw.solver.rng, max_steps=d)
    POMDPs.simulate(sim, p.mdp, p.rollout_policy, s)
end

"""
    init_Q(policy, s, a)

Return a value to initialize Q(s,a) to based on prior knowledge.

Implement a new method of this function for your custom prior knowledge type to provide an initial value based on prior knowledge.
By default, returns 0.0.
"""
init_Q{S,A,PriorKnowledgeType}(policy::AbstractMCTSPolicy{S,A,PriorKnowledgeType}, s::S, a::A) = 0.0

"""
    init_N(policy, s, a)

Return a value to initialize N(s,a) to based on prior knowledge.

Implement a new method of this function for your custom prior knowledge type to provide an initial value based on prior knowledge.
By default, returns 0.
"""
init_N{S,A,PriorKnowledgeType}(policy::AbstractMCTSPolicy{S,A,PriorKnowledgeType}, s::S, a::A) = 0
