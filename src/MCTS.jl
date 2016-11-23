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
    next_action,
    TreeVisualizer,
    clear_tree!,
    estimate_value,
    init_N,
    init_Q,
    estimate_value,
    mdp,
    rollout_policy,
    prior_knowledge

export
    StateActionStateNode,
    DPWStateActionNode,
    DPWStateNode

abstract AbstractMCTSPolicy{S,A,PriorKnowledgeType} <: Policy{S}
abstract AbstractMCTSSolver <: Solver

# public accessors for MCTS policy fields
"""
Return the mdp that the MCTS planner is using to plan.
"""
mdp(p::AbstractMCTSPolicy) = p.mdp

"""
Return the rollout policy that the MCTS planner is using.
"""
rollout_policy(p::AbstractMCTSPolicy) = p.rollout_policy

"""
Return the additional prior knowledge object.
"""
prior_knowledge(p::AbstractMCTSPolicy) = p.solver.prior_knowledge


include("prior_knowledge.jl")
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
