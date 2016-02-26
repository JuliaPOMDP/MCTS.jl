n_iter = 1000
depth = 15
ec = 3.0

solver = AgUCTSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
mdp = GridWorld()

policy = solve(solver, mdp)

state = GridWorldState(1,1)

@time a = action(policy, state)
