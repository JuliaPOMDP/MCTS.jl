function benchmark_action(n, rng, mdp, planner)
    for i in 1:n
        state = rand(rng, initialstate(mdp))
        a = action(planner, state)
    end
end


n_iter = 1000
depth = 10
ec = 10.0
RNG = MersenneTwister(1)

solver = MCTSSolver(
    n_iterations=n_iter,
    depth=depth,
    exploration_constant=ec,
    enable_tree_vis=true,
    sizehint=100_000,
    rng=RNG
)

GC.enable_logging(false)

small_mdp = SimpleGridWorld(;size=(10,10))
small_planner = solve(solver, small_mdp)
SUITE["vanilla"]["action_small"] = @benchmarkable  benchmark_action(42, $RNG, $small_mdp, $small_planner)

large_mdp = SimpleGridWorld(;size=(100,1000))
large_planner = solve(solver, large_mdp)
SUITE["vanilla"]["action_large"] = @benchmarkable  benchmark_action(42, $RNG, $large_mdp, $large_planner)