n_iter = 10000
depth = 15
ec = 3.0

solver = DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
mdp = GridWorld()

policy = solve(solver, mdp)

state = GridWorldState(1,1)

a = action(policy, state)
@time a = action(policy, state)
