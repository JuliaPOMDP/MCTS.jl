using MCTS
using POMDPModels

solver = MCTSSolver()

pomdp = GridWorld(10,10)

policy = MCTSPolicy(solver, pomdp)
state = GridWorldState(1,1)
