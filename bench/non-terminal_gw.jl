using POMDPs
using POMDPModels
using MCTS
using POMDPToolbox
using ProgressMeter
using ProfileView

sim = RolloutSimulator(max_steps=100, rng=MersenneTwister(7))

mdp = GridWorld(terminals=[])

d=20; n=100; c=10.
@show d, n, c
solver = MCTSSolver(depth=d, n_iterations=n, exploration_constant=c, rng=MersenneTwister(8))

planner = solve(solver, mdp)
simulate(sim, mdp, planner)

# @code_warntype MCTS.simulate(planner, GridWorldState(1,1,false), 10)

# Profile.clear()
# @profile for i in 1:100
#     simulate(sim, mdp, planner)
# end
# ProfileView.view()

@show N=1000
rewards = Array{Float64}(undef, N)
@time @showprogress for i = 1:N
    rewards[i] = simulate(sim, mdp, planner)
end
@show mean(rewards)
