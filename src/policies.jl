type RandomPolicy <: Policy
    mdp::POMDP # contains the model
    rng::AbstractRNG
    action_space::AbstractSpace
end
# constructor
function RandomPolicy(mdp::POMDP, rng::AbstractRNG)
    as = actions(mdp)
    return RandomPolicy(mdp, rng, as)
end

function POMDPs.action(policy::RandomPolicy, state::State, a::Action=create_action(policy.mdp))
    action_space = actions(policy.mdp, state, policy.action_space)
    return rand!(policy.rng, a, policy.action_space)
end

# a placeholder for using in a RandomPolicy when the model hasn't been assigned yet
type ModelNotAvailable <: POMDP end
type BlankSpace <: AbstractSpace end
POMDPs.actions(mdp::ModelNotAvailable) = BlankSpace()
