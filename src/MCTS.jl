module MCTS

using POMDPs

export 
    MCTSSolver, 
    MCTSPolicy,
    solve,
    action,
    simulate,
    rollout,
    # SPW
    StateNode


typealias Reward Float64

include("policies.jl")
include("vanilla.jl")

end # module
