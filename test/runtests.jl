using MCTS
using POMDPModels
using Base.Test

n_iter = 50
depth = 15
ec = 3.0

solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
mdp = GridWorld()

policy = MCTSPolicy(solver, mdp)

policy = solve(solver, mdp, policy)

state = GridWorldState(1,1)

a = action(policy, state)
