# this class should implement next_action 
abstract ActionGenerator # XXX Deprecated - only here for compatibility with POMCP

type RandomActionGenerator <: ActionGenerator
    rng::AbstractRNG
    action_space::Nullable{Any} # should be Nullable{AbstractSpace}, but https://github.com/JuliaIO/JLD.jl/issues/106
    RandomActionGenerator(rng::AbstractRNG=MersenneTwister(), action_space=nothing) = new(rng, action_space==nothing ? Nullable{Any}(): Nullable{Any}(action_space))
end

"""
MCTS solver with DPW

Fields:

    depth::Int64:
        Maximum rollout horizon and tree depth.
        default: 10

    exploration_constant::Float64: 
        Specified how much the solver should explore.
        In the UCB equation, Q + c*sqrt(log(t/N)), c is the exploration constant.
        default: 1.0

    n_iterations::Int64
        Number of iterations during each action() call.
        default: 100

    k_action::Float64
    alpha_action::Float64
    k_state::Float64
    alpha_state::Float64
        These constants control the double progressive widening. A new state
        or action will be added if the number of children is less than or equal to kN^alpha.
        defaults: k:10, alpha:0.5

    rng::AbstractRNG:
        Random number generator

    estimate_value::Any (rollout policy)
        Function, object, or number used to estimate the value at the leaf nodes.
        If this is a function `f`, `f(mdp, s, depth)` will be called to estimate the value.
        If this is an object `o`, `estimate_value(o, mdp, s, depth)` will be called.
        If this is a number, the value will be set to that number.
        default: RolloutEstimator(RandomSolver(rng))

    init_Q::Any
        Function, object, or number used to set the initial Q(s,a) value at a new node.
        If this is a function `f`, `f(mdp, s, a)` will be called to set the value.
        If this is an object `o`, `init_Q(o, mdp, s, a)` will be called.
        If this is a number, Q will always be set to that number.
        default: 0.0

    init_N::Any
        Function, object, or number used to set the initial N(s,a) value at a new node.
        If this is a function `f`, `f(mdp, s, a)` will be called to set the value.
        If this is an object `o`, `init_N(o, mdp, s, a)` will be called.
        If this is a number, N will always be set to that number.
        default: 0

    next_action::Any
        Function or object used to choose the next action to be considered for progressive widening.
        The next action is determined based on the MDP, the state, `s`, and the current `DPWStateNode`, `snode`.
        If this is a function `f`, `f(mdp, s, snode)` will be called to set the value.
        If this is an object `o`, `next_action(o, mdp, s, snode)` will be called.
        default: RandomActionGenerator(rng)
"""
type DPWSolver <: AbstractMCTSSolver
    depth::Int
    exploration_constant::Float64
    n_iterations::Int
    k_action::Float64
    alpha_action::Float64
    k_state::Float64
    alpha_state::Float64
    rng::AbstractRNG
    estimate_value::Any
    init_Q::Any
    init_N::Any
    next_action::Any
end

"""
    DPWSolver()

Use keyword arguments to specify values for the fields
"""
function DPWSolver(;depth::Int=10,
                    exploration_constant::Float64=1.0,
                    n_iterations::Int=100,
                    k_action::Float64=10.0,
                    alpha_action::Float64=0.5,
                    k_state::Float64=10.0,
                    alpha_state::Float64=0.5,
                    rng::AbstractRNG=MersenneTwister(),
                    estimate_value::Any = RolloutEstimator(RandomSolver(rng)),
                    init_Q::Any = 0.0,
                    init_N::Any = 0,
                    next_action::Any = RandomActionGenerator(rng))
    DPWSolver(depth, exploration_constant, n_iterations, k_action, alpha_action, k_state, alpha_state, rng, estimate_value, init_Q, init_N, next_action)
end

type StateActionStateNode
    N::Int
    R::Float64
    StateActionStateNode() = new(0,0)
end

type DPWStateActionNode{S}
    V::Dict{S,StateActionStateNode}
    N::Int
    Q::Float64
    DPWStateActionNode(N,Q) = new(Dict{S,StateActionStateNode}(), N, Q)
end

type DPWStateNode{S,A}
    A::Dict{A,DPWStateActionNode{S}}
    N::Int
    DPWStateNode() = new(Dict{A,DPWStateActionNode{S}}(),0)
end

type DPWPolicy{S,A} <: AbstractMCTSPolicy{S,A}
    solver::DPWSolver
    mdp::Union{POMDP{S,A},MDP{S,A}}
    tree::Dict{S,DPWStateNode{S,A}} 
    solved_estimate::Any
end

function DPWPolicy{S,A}(solver::DPWSolver, mdp::Union{POMDP{S,A},MDP{S,A}})
    return DPWPolicy{S,A}(solver,
                          mdp,
                          Dict{S,DPWStateNode{S,A}}(),
                          SolvedRolloutEstimator(RandomPolicy(mdp, rng=solver.rng), solver.rng))
end
