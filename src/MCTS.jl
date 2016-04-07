module MCTS

using POMDPs
using GenerativeModels
using POMDPToolbox

export 
    MCTSSolver, 
    MCTSPolicy,
    DPWSolver,
    DPWPolicy,
    AgUCTSolver,
    AgUCTPolicy,
    solve,
    action,
    rollout,
    StateNode,
    ActionGenerator,
    RandomActionGenerator,
    TreeVisualizer

abstract AbstractMCTSPolicy <: Policy
abstract AbstractMCTSSolver <: Solver

"""
Includes all MDPs and POMDPs, this allows MCTS to be used with a POMDP.

When a POMDP is supplied, MCTS solves the fully-observable relaxation. Note also that every MDP is a PermissiveMDP.

This may be removed in the future.
"""
typealias PermissiveMDP{S,A,_} POMDP{S,A,_}

include("vanilla.jl")
include("dpw_types.jl")
include("dpw.jl")
include("action_gen.jl")
include("aggregation.jl")

include("visualization.jl")

end # module
