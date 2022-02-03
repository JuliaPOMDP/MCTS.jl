using POMDPs
using MCTS
using POMDPModels
using POMDPSimulators

# function POMDPs.simulate(mdp::POMDP,
#                          policy::Policy,
#                          initialstate::Any,
#                          rng::AbstractRNG = MersenneTwister(rand(Uint32)),
#                          eps::Float64 = 0.0)

#     disc = 1.0
#     r = 0.0
#     s = deepcopy(initialstate)

#     trans_dist = create_transition_distribution(mdp)

#     while disc > eps && !isterminal(mdp, s)

#         a = action(policy, s)
#         r += disc * reward(mdp, s, a)

#         transition!(trans_dist, mdp, s, a)
#         rand!(rng, s, trans_dist)

#         disc *= discount(mdp)
#     end

#     return r
# end

##############################


function run_batch(n::Int64,
                   mdp::MDP,
                   policy::Policy,
                   initialstate::Any;
                   rng = MersenneTwister(rand(UInt32)),
                   eps = 0.0)
    rewards = zeros(n)
    space = states(mdp)
    s = rand(space)
    while POMDPs.isterminal(mdp, s) && reward(mdp, s)>0.0
        s = rand(space)
    end
    ro = RolloutSimulator(rng=rng, eps=eps)
    for i = 1:n
        rewards[i] = POMDPs.simulate(ro, mdp, policy, initialstate)
    end
    return mean(rewards)
end

##############################

mdp = SimpleGridWorld(size = (10, 10))
rewards = zeros(20, 9)
initialstate = GWPos(1, 1)
n = 300

for (i, d) in enumerate(1:20), (j, ec) in enumerate(0.0:0.5:4.0)
    println("On: $d, $ec, $i, $j")
    mcts = MCTSSolver(depth = d, exploration_constant = ec)
    policy = MCTSPlanner(mcts, mdp)
    rewards[i, j] = run_batch(n, mdp, policy, initialstate, eps = 0.5)
end
