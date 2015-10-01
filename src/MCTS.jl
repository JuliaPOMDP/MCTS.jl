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


include("spw.jl")
#include("dpw.jl")

end # module
