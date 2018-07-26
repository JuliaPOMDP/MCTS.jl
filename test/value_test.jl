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

ad = Dict()
for s in test_states
    ad[s] = action(vip, s)
end

@show ad

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
