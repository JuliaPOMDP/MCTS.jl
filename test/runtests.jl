using MCTS
using POMDPs
using POMDPModels
using Test
using NBInclude
using D3Trees
using Random
using POMDPTools
using POMDPLinter: @requirements_info

n_iter = 50
depth = 15
ec = 1.0

println("Testing vanilla MCTS solver.")

solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = SimpleGridWorld()

struct A
    a::Vector{Int}
end

@testset "requirements_info" begin
    # println("============== @requirements_info with only solver:")
    @test_skip @requirements_info solver
    # println("============== @requirements_info with solver and mdp:")
    @test_skip @requirements_info solver mdp
    # println("============== @requirements_info with solver, mdp, and state:")
    @test_skip @requirements_info solver mdp GWPos(1,1)
    # println("============== isequal and hash warnings:")
    @test_skip @requirements_info solver mdp A([1,2,3])
end

policy = solve(solver, mdp)

state = GWPos(1,1)

@testset "basic" begin
    a = @inferred action(policy, state)
    a, info = action_info(policy, state)

    tree = policy.tree
    @test tree.state_map[state] == 1
    @test info[:tree].state_map[state] == 1

    clear_tree!(policy)
    @test isempty(policy.tree)
end

@testset "value" begin
    include("value_test.jl")
end

@testset "options" begin
    include("options.jl")
end

@testset "dpw" begin
    include("dpw_test.jl")
end

@testset "visualization" begin
    include("visualization.jl")
end
@nbinclude("../notebooks/Test_Visualization.ipynb")

@testset "other" begin
    include("other.jl")
end

# # test the BeliefMCTSSolver docstring
# let
#     using ParticleFilters
#     using POMDPModels
#     using MCTS
#     using POMDPToolbox

#     pomdp = BabyPOMDP()
#     updater = SIRParticleFilter(pomdp, 1000)

#     solver = BeliefMCTSSolver(DPWSolver(), updater)
#     planner = solve(solver, pomdp)

#     @inferred action(planner, initialize_belief(updater, initialstate_distribution(pomdp)))

#     simulate(HistoryRecorder(max_steps=10), pomdp, planner, updater)
# end

@testset "timing" begin
    solver = DPWSolver(n_iterations=typemax(Int),
                       depth=depth,
                       max_time=1.0,
                       exploration_constant=ec)
    mdp = SimpleGridWorld()

    policy = solve(solver, mdp)
    state = GWPos(1,1)
    a = action(policy, state)
    t = @elapsed begin
        action(policy, state)
    end
    @test abs(t-1.0) < 0.5

    solver = MCTSSolver(n_iterations=typemax(Int),
                       depth=depth,
                       max_time=1.0,
                       exploration_constant=ec)
    mdp = SimpleGridWorld()

    policy = solve(solver, mdp)
    state = GWPos(1,1)
    a = action(policy, state)
    t = @elapsed begin
        action(policy, state)
    end
    @test abs(t-1.0) < 0.5

end


# This test only seems to make sense with LegacyGridWorld, not with SimpleGridWorld.
# @testset "terminal state" begin
#     solver = DPWSolver(n_iterations=typemax(Int),
#                     depth=depth,
#                     max_time=1.0,
#                     exploration_constant=ec)

#     terminal_state = GWPos(1,1)
#     mdp = SimpleGridWorld(terminate_from=Set([terminal_state,]))

#     policy = solve(solver, mdp)
#     # @test_throws ErrorException action(policy, terminal_state)
# end

@testset "c=0" begin
    mdp = SimpleGridWorld()

    solver = DPWSolver(n_iterations=typemax(Int),
                       depth=depth,
                       max_time=1.0,
                       exploration_constant=0.0)

    policy = solve(solver, mdp)
    state = GWPos(1,1)
    action(policy, state)

    solver = MCTSSolver(exploration_constant=0.0)

    policy = solve(solver, mdp)
    state = GWPos(1,1)
    action(policy, state)
end

@testset "default_action" begin
    sol = DPWSolver(default_action=:up, estimate_value=error)
    p = solve(sol, mdp)
    @test_logs (:warn,) action(p, state)

    sol = DPWSolver(default_action=ReportWhenUsed(:up), estimate_value=error)
    p = solve(sol, mdp)
    @test_logs (:warn,) (:warn,) (:warn,) action(p, state)
end

@nbinclude("../notebooks/Domain_Knowledge_Example.ipynb")

@testset "Discussion 514" begin
    include("discussion_514.jl")
end
