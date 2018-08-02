using MCTS
using POMDPs
using POMDPModels
using Base.Test
using NBInclude
using POMDPToolbox
using D3Trees

n_iter = 50
depth = 15
ec = 1.0

println("Testing vanilla MCTS solver.")

solver = MCTSSolver(n_iterations=n_iter, depth=depth, exploration_constant=ec, enable_tree_vis=true)
mdp = GridWorld()

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

a = @inferred action(policy, state)

clear_tree!(policy)
@test isnull(policy.tree)

include("value_test.jl")

include("options.jl")

println("Testing DPW solver.")
include("dpw_test.jl")

println("Testing visualization.")
include("visualization.jl")
@nbinclude("../notebooks/Test_Visualization.ipynb")

println("Testing other functions.")
include("other.jl")

# test the BeliefMCTSSolver docstring
let
    using ParticleFilters
    using POMDPModels
    using MCTS
    using POMDPToolbox

    pomdp = BabyPOMDP()
    updater = SIRParticleFilter(pomdp, 1000)

    solver = BeliefMCTSSolver(DPWSolver(), updater)
    planner = solve(solver, pomdp)

    @inferred action(planner, initialize_belief(updater, initial_state_distribution(pomdp)))

    simulate(HistoryRecorder(max_steps=10), pomdp, planner, updater)
end

# test timing
let
    solver = DPWSolver(n_iterations=typemax(Int),
                       depth=depth,
                       max_time=1.0,
                       exploration_constant=ec)
    mdp = GridWorld()

    policy = solve(solver, mdp)
    state = GridWorldState(1,1)
    a = action(policy, state)
    t = begin
        tic()
        action(policy, state)
        toc()
    end
    @test abs(t-1.0) < 0.5
end

# test terminal state error
let
    solver = DPWSolver(n_iterations=typemax(Int),
                       depth=depth,
                       max_time=1.0,
                       exploration_constant=ec)
    mdp = GridWorld()

    policy = solve(solver, mdp)
    state = GridWorldState(1,1,true)
    @test_throws ErrorException action(policy, state)
end

# test c=0.0
let
    mdp = GridWorld()

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

@nbinclude("../notebooks/Domain_Knowledge_Example.ipynb")
