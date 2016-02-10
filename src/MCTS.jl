module MCTS

using POMDPs

export 
    MCTSSolver, 
    MCTSPolicy,
    solve,
    action,
    rollout,
    StateNode,
    TreeVisualizer


typealias Reward Float64

include("policies.jl")
include("simulators.jl")
include("vanilla.jl")

include("visualization.jl")

end # module
