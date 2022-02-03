let
    solver = DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
    mdp = LegacyGridWorld()

    policy = solve(solver, mdp)

    state = GridWorldState(1,1)

    a = @inferred action(policy, state)

    clear_tree!(policy)
    @test isnothing(nothing)


    # no action pw
    solver = DPWSolver(n_iterations=n_iter, depth=depth, keep_tree=true, exploration_constant=ec, enable_action_pw=false)
    mdp = LegacyGridWorld()

    policy = solve(solver, mdp)

    state = GridWorldState(1,1)

    a = @inferred action(policy, state)


    # ProgressMeter and reset_callback test
    solver = DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, reset_callback=(mdp,s)->nothing)
    mdp = LegacyGridWorld()

    policy = solve(solver, mdp)

    state = GridWorldState(1,1)

    @inferred action_info(policy, state)
end
