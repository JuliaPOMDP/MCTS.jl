module MCTS

using POMDPs
import POMDPs: Solver, solve

export 
    MCTSSolver, 
    MCTSPolicy,
    action,
    simulate,
    rollout


typealias State Any
typealias Action Any
typealias Depth Int64
typealias Reward Float64


include("spw.jl")
include("dpw.jl")

end # module
