using POMDPModels
using Test

# test ranked_actions for vanilla
solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = LegacyGridWorld()

policy = solve(solver, mdp)

state = GridWorldState(1,1)

a = action(policy, state)

ranked = MCTS.ranked_actions(policy, state)

@test first(ranked[1]) == a

# test ranked_actions for dpw
solver = DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec)
mdp = LegacyGridWorld()

policy = solve(solver, mdp)

state = GridWorldState(1,1)

a = action(policy, state)

ranked = MCTS.ranked_actions(policy, state)

@test first(ranked[1]) == a
