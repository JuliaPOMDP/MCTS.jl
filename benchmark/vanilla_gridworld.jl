solver = MCTSSolver(
    n_iterations=1000,
    depth=10,
    exploration_constant=10.0, # most transitions in GW have 0.0 reward, some cells have between -10 and 10
    enable_tree_vis=false,
    reuse_tree=false,
    rng = MersenneTwister(1)    
)
mdp = SimpleGridWorld(;
    size=(10,10), 
    terminate_from=Set()) # removes ipact of terminal states on benchmarking, making all rollouts of same length

mcts = solve(solver, mdp)
state = GWPos(5,5)
SUITE["vanilla"]["gridworld"] = @benchmarkable action($mcts, $state)