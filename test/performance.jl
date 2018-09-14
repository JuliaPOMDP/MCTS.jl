# tests performance compared with discrete value iteration
using MCTS
using POMDPModels
using DiscreteValueIteration
using POMDPs

mdp = LegacyGridWorld()
N = 50
rng = MersenneTwister(1)
init_states = [GridWorldState(rand(rng, 1:mdp.size_x), rand(rng, 1:mdp.size_y)) for i in 1:N]

solvers = Dict(:vi => ValueIterationSolver(),
               :mcts1k => MCTSSolver(n_iterations=1000,
                                   depth=20,
                                   exploration_constant=10.0),
               :mcts10k => MCTSSolver(n_iterations=10000,
                                   depth=20,
                                   exploration_constant=10.0),
               :dpw => DPWSolver(n_iterations=1000,
                                 depth=20,
                                 exploration_constant=10.0,
                                 k_action=100.0, # these are all just set to large values so that behavior should be equivalent to MCTS
                                 alpha_action=1.0,
                                 k_state=100.0,
                                 alpha_action=1.0,
                                 ))

policies = Dict([(k, solve(s,mdp)) for (k,s) in solvers])
rewards = SharedArray(Float64, length(solvers), N)
index = Dict([(k, i) for (i, k) in enumerate(keys(solvers))])

for (k,p) in policies
    println("simulating $k")
    # @time @sync @parallel for i in 1:N
    @time for i in 1:N
        sim = MCTS.RolloutSimulator(rng=MersenneTwister(i))
        rewards[index[k],i] = simulate(sim, mdp, deepcopy(p), init_states[i])
    end
end

r = sdata(rewards)
for (k,i) in index
    println("$k: $(mean(r[i,:]))")
end
