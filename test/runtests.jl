using MCTS
using POMDPModels
using Base.Test

@show MCTS.required_methods()

n_iter = 50
depth = 15
ec = 1.0

println("Testing vanilla MCTS solver.")

solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = GridWorld()

policy = solve(solver, mdp)

state = GridWorldState(1,1)

a = action(policy, state)

clear_tree!(policy)
@test isempty(policy.tree)

println("Testing DPW solver.")
include("dpw_test.jl")

println("Testing aggregating MCTS solver.")
include("aggregation_test.jl")

println("Testing visualization constructor.")
include("visualization.jl")

println("Testing other functions.")
include("other.jl")
