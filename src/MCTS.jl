__precompile__()
module MCTS

using POMDPs
using POMDPToolbox

using Compat
using Blink

export
    MCTSSolver,
    MCTSPlanner,
    DPWSolver,
    DPWPlanner,
    AbstractMCTSPlanner,
    AbstractMCTSSolver,
    solve,
    action,
    rollout,
    StateNode,
    RandomActionGenerator,
    RolloutEstimator,
    next_action,
    AbstractTreeVisualizer,
    TreeVisualizer,
    blink,
    inchrome,
    clear_tree!,
    estimate_value,
    init_N,
    init_Q

export
    AbstractStateNode,
    StateActionStateNode,
    DPWStateActionNode,
    DPWStateNode

abstract type AbstractMCTSPlanner{P<:Union{MDP,POMDP}} <: Policy end
abstract type AbstractMCTSSolver <: Solver end
abstract type AbstractStateNode end

include("requirements_info.jl")
include("domain_knowledge.jl")
include("vanilla.jl")
include("dpw_types.jl")
include("dpw.jl")
include("action_gen.jl")
include("util.jl")

include("visualization.jl")

end # module
