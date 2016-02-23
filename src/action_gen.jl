function next_action(gen::RandomActionGenerator, mdp::POMDP, s::State, snode::DPWStateNode)
    if gen.action_space == nothing
        gen.action_space = actions(mdp)
    end
    rand(gen.rng, actions(mdp, s, gen.action_space))
end
