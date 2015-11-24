module MCTS

using POMDPs

export 
    MCTSSolver, 
    MCTSPolicy,
    action,
    simulate,
    rollout,
    # SPW
    StateNode


typealias Reward Float64

include("policies.jl")
include("vanilla.jl")

end # module
