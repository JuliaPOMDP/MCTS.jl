using POMDPModels

# test ranked_actions for vanilla
solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = SimpleGridWorld()

policy = solve(solver, mdp)

state = GWPos(1,1)

a = action(policy, state)

ranked = MCTS.ranked_actions(policy, state)

@test first(ranked[1]) == a

# test ranked_actions for dpw
solver = DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
mdp = SimpleGridWorld()

policy = solve(solver, mdp)

state = GWPos(1,1)

a = action(policy, state)

ranked = MCTS.ranked_actions(policy, state)

@test first(ranked[1]) == a
