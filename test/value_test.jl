using POMDPModels
using MCTS

gw = GridWorld()

# The commented-out code below can be used to generate ad. It is hard-coded here to avoid the dependency.

# using DiscreteValueIteration
# using Base.Test
# 
# vis = ValueIterationSolver()
# vip = solve(vis, gw)
# 
# test_states = GridWorldState[]
# 
# for i in [1, 3, 5, 9]
#     for j in [1, 3, 5, 9]
#         push!(test_states, GridWorldState(i,j))
#     end
# end
# 
# ad = Dict{GridWorldState, Symbol}()
# for s in test_states
#     ad[s] = action(vip, s)
# end
# 
# @show ad


ad = Dict(POMDPModels.GridWorldState(1, 9, false)=>:right,
          POMDPModels.GridWorldState(9, 9, false)=>:down,
          POMDPModels.GridWorldState(5, 9, false)=>:down,
          POMDPModels.GridWorldState(3, 5, false)=>:right,
          POMDPModels.GridWorldState(1, 5, false)=>:right,
          POMDPModels.GridWorldState(5, 3, false)=>:right,
          POMDPModels.GridWorldState(3, 3, false)=>:down,
          POMDPModels.GridWorldState(1, 1, false)=>:right,
          POMDPModels.GridWorldState(3, 9, false)=>:right,
          POMDPModels.GridWorldState(1, 3, false)=>:down,
          POMDPModels.GridWorldState(9, 3, false)=>:up,
          POMDPModels.GridWorldState(9, 5, false)=>:down,
          POMDPModels.GridWorldState(5, 5, false)=>:right,
          POMDPModels.GridWorldState(9, 1, false)=>:up,
          POMDPModels.GridWorldState(3, 1, false)=>:right,
          POMDPModels.GridWorldState(5, 1, false)=>:right)

ms = MCTSSolver(n_iterations=10_000,
                depth=20,
                exploration_constant=20.0,
                # estimate_value=(mdp, s, d)->value(vip, s),
                rng=MersenneTwister(43)
               )
mp = solve(ms, gw)

mavals = []
avals = []
for (s, a) in ad
    clear_tree!(mp)
    ma = action(mp, s)
    push!(mavals, value(mp, s, ma))
    push!(avals, value(mp, s, a))
end

# test that the values of the true best actions and the predicted best actions are not that far apart on average
@test mean(abs, mavals-avals) < 1.0
