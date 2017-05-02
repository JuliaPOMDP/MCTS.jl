using POMDPs
using POMDPModels
using MCTS
using POMDPToolbox
using ProgressMeter
using ProfileView

sim = RolloutSimulator(max_steps=100, rng=MersenneTwister(7))

mdp = GridWorld(terminals=[])

d=20; n=1000; c=10.
@show d, n, c
solver = DPWSolver(depth=d,
                   n_iterations=n,
                   exploration_constant=c,
                   k_state=4.0,
                   alpha_state=1/8,
                   k_action=4.0,
                   alpha_action=1/8,
                   rng=MersenneTwister(8))

planner = solve(solver, mdp)
simulate(sim, mdp, planner)

# @code_warntype MCTS.simulate(planner, GridWorldState(1,1,false), 10)

Profile.clear()
@profile for i in 1:1
    simulate(sim, mdp, planner)
end
ProfileView.view()

# @show N=100
# rewards = Array(Float64, N)
# @time @showprogress for i = 1:N
#     rewards[i] = simulate(sim, mdp, planner)
# end
# @show mean(rewards)
