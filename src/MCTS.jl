module MCTS

using POMDPs
using GenerativeModels
using POMDPToolbox

using Compat

export 
    MCTSSolver, 
    MCTSPolicy,
    DPWSolver,
    DPWPolicy,
    AbstractMCTSPolicy,
    AbstractMCTSSolver,
    solve,
    action,
    rollout,
    StateNode,
    ActionGenerator,
    RandomActionGenerator,
    RolloutEstimate,
    next_action,
    TreeVisualizer,
    clear_tree!,
    estimate_value,
    init_N,
    init_Q

export
    StateActionStateNode,
    DPWStateActionNode,
    DPWStateNode

abstract AbstractMCTSPolicy{S,A} <: Policy{S}
abstract AbstractMCTSSolver <: Solver

include("domain_knowledge.jl")
include("vanilla.jl")
include("dpw_types.jl")
include("dpw.jl")
include("action_gen.jl")
include("util.jl")

include("visualization.jl")

function required_methods()
    println("Note: the required_methods() list of functions for MCTS contains generate_sr() from the GenerativeModels package. Alternatively, it is sufficient to define transition() and reward() from POMDPs instead.")
    return [
        generate_sr,
        discount,
        actions,
        isterminal,
        rand
    ]
end

end # module
