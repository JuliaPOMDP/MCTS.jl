n_iter = 10000
depth = 15
ec = 3.0

solver = AgUCTSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = GridWorld()

policy = solve(solver, mdp)

state = GridWorldState(1,1)

a = action(policy, state)
@time a = action(policy, state)
