type RandomPolicy <: Policy
    mdp::POMDP # contains the model
    rng::AbstractRNG
    action_space::AbstractSpace
    action::Action
end
# constructor
function RandomPolicy(mdp::POMDP, rng::AbstractRNG)
    as = actions(mdp)
    a = create_action(mdp)
    return RandomPolicy(mdp, rng, as, a)
end


function POMDPs.action(policy::RandomPolicy, state::State)
    action_space = actions(policy.mdp, state, policy.action_space)
    return rand!(policy.rng, policy.action, policy.action_space)
end
