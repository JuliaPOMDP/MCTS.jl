using POMDPModels
using MCTS

gw = SimpleGridWorld()

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


ad = Dict(GWPos(1, 9)=>:right,
          GWPos(9, 9)=>:down,
          GWPos(5, 9)=>:down,
          GWPos(3, 5)=>:right,
          GWPos(1, 5)=>:right,
          GWPos(5, 3)=>:right,
          GWPos(3, 3)=>:down,
          GWPos(1, 1)=>:right,
          GWPos(3, 9)=>:right,
          GWPos(1, 3)=>:down,
          GWPos(9, 3)=>:up,
          GWPos(9, 5)=>:down,
          GWPos(5, 5)=>:right,
          GWPos(9, 1)=>:up,
          GWPos(3, 1)=>:right,
          GWPos(5, 1)=>:right)

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
