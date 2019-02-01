using MCTS
using POMDPs
using POMDPModels
using Test
using NBInclude
using D3Trees
using Random
using POMDPPolicies

n_iter = 50
depth = 15
ec = 1.0

println("Testing vanilla MCTS solver.")

solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = LegacyGridWorld()

struct A
    a::Vector{Int}
end

println("============== @requirements_info with only solver:")
@requirements_info solver
println("============== @requirements_info with solver and mdp:")
@requirements_info solver mdp
println("============== @requirements_info with solver, mdp, and state:")
@requirements_info solver mdp GridWorldState(1,1)
println("============== isequal and hash warnings:")
@requirements_info solver mdp A([1,2,3])

policy = solve(solver, mdp)

state = GridWorldState(1,1)

@testset "basic" begin
    a = @inferred action(policy, state)

    tree = policy.tree
    @test get_state_node(tree, state).id == 1
    @test get_state_node(tree, state, policy).id == 1

    clear_tree!(policy)
    @test policy.tree == nothing
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
    mdp = LegacyGridWorld()

    policy = solve(solver, mdp)
    state = GridWorldState(1,1)
    a = action(policy, state)
    t = @elapsed begin
        action(policy, state)
    end
    @test abs(t-1.0) < 0.5
end

@testset "timing" begin
    solver = DPWSolver(n_iterations=typemax(Int),
                       depth=depth,
                       max_time=1.0,
                       exploration_constant=ec)
    mdp = LegacyGridWorld()

    policy = solve(solver, mdp)
    state = GridWorldState(1,1,true)
    @test_throws ErrorException action(policy, state)
end

@testset "c=0" begin
    mdp = LegacyGridWorld()

    solver = DPWSolver(n_iterations=typemax(Int),
                       depth=depth,
                       max_time=1.0,
                       exploration_constant=0.0)

    policy = solve(solver, mdp)
    state = GridWorldState(1,1)
    action(policy, state)

    solver = MCTSSolver(exploration_constant=0.0)

    policy = solve(solver, mdp)
    state = GridWorldState(1,1)
    action(policy, state)
end

@testset "default_action" begin
    sol = DPWSolver(default_action=:up, estimate_value=error)
    p = solve(sol, mdp)
    println("There should be a warning below:")
    action(p, state)
end

@nbinclude("../notebooks/Domain_Knowledge_Example.ipynb")
