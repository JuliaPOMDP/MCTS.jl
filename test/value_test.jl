using POMDPModels
using DiscreteValueIteration
using Base.Test
using MCTS

vis = ValueIterationSolver()
gw = GridWorld()
vip = solve(vis, gw)

test_states = GridWorldState[]

for i in [1, 3, 5, 9]
    for j in [1, 3, 5, 9]
        push!(test_states, GridWorldState(i,j))
    end
end

vd = Dict{GridWorldState, Float64}()
for s in test_states
    vd[s] = value(vip, s)
end

@show vd

vd = Dict(
  POMDPModels.GridWorldState(1, 9, false) => 3.02288,
  POMDPModels.GridWorldState(9, 9, false) => 5.27214,
  POMDPModels.GridWorldState(5, 9, false) => 4.1627,
  POMDPModels.GridWorldState(3, 5, false) => 4.06859,
  POMDPModels.GridWorldState(1, 5, false) => 3.39106,
  POMDPModels.GridWorldState(5, 3, false) => 5.48977,
  POMDPModels.GridWorldState(3, 3, false) => 3.06061,
  POMDPModels.GridWorldState(1, 1, false) => 3.90453,
  POMDPModels.GridWorldState(3, 9, false) => 3.52814,
  POMDPModels.GridWorldState(1, 3, false) => 3.43752,
  POMDPModels.GridWorldState(9, 3, false) => 10.0,
  POMDPModels.GridWorldState(9, 5, false) => 8.15886,
  POMDPModels.GridWorldState(5, 5, false) => 5.74464,
  POMDPModels.GridWorldState(9, 1, false) => 8.23636,
  POMDPModels.GridWorldState(3, 1, false) => 4.77811,
  POMDPModels.GridWorldState(5, 1, false) => 6.04952,
)

ms = MCTSSolver(n_iterations=100_000,
                depth=20,
                exploration_constant=2.0,
                estimate_value=(mdp, s, d)->value(vip, s),
                rng=MersenneTwister(6)
               )
mp = solve(ms, gw)

for (s, v) in vd
    clear_tree!(mp)
    @show v
    @show value(mp, s)
end
