using MCTS
using POMDPs
using POMDPModels
using Base.Test
using NBInclude
using POMDPToolbox

n_iter = 50
depth = 15
ec = 1.0

println("Testing vanilla MCTS solver.")

solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = GridWorld()

println("============== @requirements_info with only solver:")
@requirements_info solver
println("============== @requirements_info with solver and mdp:")
@requirements_info solver mdp
println("============== @requirements_info with solver, mdp, and state:")
@requirements_info solver mdp GridWorldState(1,1)

policy = solve(solver, mdp)

state = GridWorldState(1,1)

a = action(policy, state)

# MCTS.blink(TreeVisualizer(policy, state))

clear_tree!(policy)
@test isempty(policy.tree)

include("options.jl")

println("Testing DPW solver.")
include("dpw_test.jl")

# println("Testing visualization.")
# include("visualization.jl")
# nbinclude("../notebooks/Test_Visualization.ipynb")

println("Testing other functions.")
include("other.jl")

nbinclude("../notebooks/Domain_Knowledge_Example.ipynb")
