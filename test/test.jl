using MCTS
using POMDPModels

n_iter = 50
depth = 15
ec = 3.0

solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
mdp = GridWorld(10,10)

policy = MCTSPolicy(solver, mdp)
state = GridWorldState(1,1)
