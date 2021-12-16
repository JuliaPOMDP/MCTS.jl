using POMDPs
using POMDPModels                                                                                                          
using MCTS
using StaticArrays


mdp = SimpleGridWorld()
solver = MCTSSolver(n_iterations=100_000, depth=20, exploration_constant=5.0)
planner = solve(solver, mdp)
a = action(planner, SA[1,2])
