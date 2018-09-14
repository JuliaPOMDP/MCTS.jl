function test_solver_options(solver::AbstractMCTSSolver)
    mdp = LegacyGridWorld()
    policy = solve(solver, mdp)
    state = GridWorldState(1,1)
    a = action(policy, state)
end

mutable struct DomanKnowledgeTestTp end

MCTS.init_Q(d::DomanKnowledgeTestTp, mdp::LegacyGridWorld, s, a) = -1.0
MCTS.init_N(d::DomanKnowledgeTestTp, mdp::LegacyGridWorld, s, a) = 2
MCTS.estimate_value(d::DomanKnowledgeTestTp, mdp::LegacyGridWorld, s, depth::Int) = 4.0
MCTS.next_action(d::DomanKnowledgeTestTp, mdp::LegacyGridWorld, s, snode::DPWStateNode) = rand(Random.GLOBAL_RNG, actions(mdp))

test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_Q=1.0))
test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_Q=(mdp, s, a)->5.0))
test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_Q=DomanKnowledgeTestTp()))
@test_throws MethodError test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_Q="bad"))

test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_N=3))
test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_N=(mdp, s, a)->9))
test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_N=DomanKnowledgeTestTp()))
@test_throws MethodError test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_N="bad"))

test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=3.0))
test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=(mdp, s, d)->9))
test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=DomanKnowledgeTestTp()))
test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=RolloutEstimator(RandomPolicy(LegacyGridWorld(), rng=Random.GLOBAL_RNG))))
test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=RolloutEstimator(x->GridWorldAction(:up))))
@test_throws MethodError test_solver_options(MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value="bad"))

test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_Q=1.0))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_Q=(mdp, s, a)->5.0))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_Q=DomanKnowledgeTestTp()))
@test_throws MethodError test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_Q="bad"))

test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_N=3))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_N=(mdp, s, a)->9))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_N=DomanKnowledgeTestTp()))
@test_throws MethodError test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, init_N="bad"))

test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=3.0))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=(mdp, s, d)->9))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=DomanKnowledgeTestTp()))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=RolloutEstimator(RandomPolicy(LegacyGridWorld(), rng=Random.GLOBAL_RNG))))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value=RolloutEstimator(x->GridWorldAction(:up))))
@test_throws MethodError test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, estimate_value="bad"))

test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, next_action=(mdp, s, snode)->GridWorldAction(:up)))
test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, next_action=DomanKnowledgeTestTp()))
@test_throws MethodError test_solver_options(DPWSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, next_action="bad"))
