let
    solver = DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
    mdp = LegacyGridWorld()

    policy = solve(solver, mdp)

    state = GridWorldState(1,1)

    a = @inferred action(policy, state)

    clear_tree!(policy)
    @test policy.tree == nothing


    # no action pw
    solver = DPWSolver(n_iterations=n_iter, depth=depth, keep_tree=true, exploration_constant=ec, enable_action_pw=false)
    mdp = LegacyGridWorld()

    policy = solve(solver, mdp)

    state = GridWorldState(1,1)

    a = @inferred action(policy, state)
end
