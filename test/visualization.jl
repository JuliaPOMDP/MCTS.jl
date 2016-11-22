# normal
# solver = AgUCTSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = GridWorld()

policy = solve(solver, mdp)

state = GridWorldState(1,1)

a = action(policy, state)

v = TreeVisualizer(policy, state)
json = MCTS.create_json(v)

# dpw
solver = DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
mdp = GridWorld()

policy = solve(solver, mdp)

state = GridWorldState(1,1)

a = action(policy, state)

v = TreeVisualizer(policy, state)
json = MCTS.create_json(v)

dummy = IOBuffer()
show(dummy, MIME("text/html"), v)
