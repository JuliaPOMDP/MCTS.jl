function benchmark_action(n, rng, mdp, planner)
    for i in 1:n
        state = rand(rng, initialstate(mdp))
        a = action(planner, state)
    end
end


n_iter = 1000
depths = [10, 100, 1000]
ec = 10.0
RNG = MersenneTwister(1)

GC.enable_logging(false)

get_solver(depth) = MCTSSolver(
    n_iterations=n_iter,
    depth=depth,
    exploration_constant=ec,
    enable_tree_vis=false,
    # sizehint=100_000,
    rng=RNG
)

gw_sizes = [(10,10), (1_000,1_000), (1_000_000,1_000_000)]

for size in gw_sizes
    for depth in depths
        mdp = SimpleGridWorld(;size=size)
        planner = solve(get_solver(depth), mdp)
        name = "gw_$(size[1])x$(size[2])_d$depth"
        # println("gw_$(size[1])x$(size[2])_d$depth")
        SUITE["vanilla"][name] = @benchmarkable  benchmark_action(42, $RNG, $mdp, $planner)
    end
end