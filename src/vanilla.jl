mutable struct MCTSTree{S,A}
    state_map::Dict{S,Int}

    # these vectors have one entry for each state node
    children::Vector{Vector{Int}}
    total_n::Vector{Int}
    s_labels::Vector{S}

    # these vectors have one entry for each action node
    n::Vector{Int}
    q::Vector{Float64}
    a_labels::Vector{A}

    _vis_stats::Nullable{Any}

    function MCTSTree{S,A}(sz::Int=1000) where {S,A}
        sz = min(sz, 100_000)

        return new(Dict{S, Int}(),

                   sizehint!(Vector{Int}[], sz),
                   sizehint!(Int[], sz),
                   sizehint!(S[], sz),

                   sizehint!(Int[], sz),
                   sizehint!(Float64[], sz),
                   sizehint!(A[], sz),

                   Nullable{Any}()
                  )
    end
end

struct StateNode{S}
    tree::MCTSTree{S}
    id::Int
end

state(n::StateNode) = n.s_labels[n.id]



"""
MCTS solver type

Fields:

    n_iterations::Int64
        Number of iterations during each action() call.
        default: 100

    depth::Int64:
        Maximum rollout horizon and tree depth.
        default: 10

    exploration_constant::Float64:
        Specifies how much the solver should explore.
        In the UCB equation, Q + c*sqrt(log(t/N)), c is the exploration constant.
        default: 1.0

    rng::AbstractRNG:
        Random number generator

    estimate_value::Any (rollout policy)
        Function, object, or number used to estimate the value at the leaf nodes.
        If this is a function `f`, `f(mdp, s, depth)` will be called to estimate the value.
        If this is an object `o`, `estimate_value(o, mdp, s, depth)` will be called.
        If this is a number, the value will be set to that number
        default: RolloutEstimator(RandomSolver(rng))

    init_Q::Any
        Function, object, or number used to set the initial Q(s,a) value at a new node.
        If this is a function `f`, `f(mdp, s, a)` will be called to set the value.
        If this is an object `o`, `init_Q(o, mdp, s, a)` will be called.
        If this is a number, Q will be set to that number
        default: 0.0

    init_N::Any
        Function, object, or number used to set the initial N(s,a) value at a new node.
        If this is a function `f`, `f(mdp, s, a)` will be called to set the value.
        If this is an object `o`, `init_N(o, mdp, s, a)` will be called.
        If this is a number, N will be set to that number
        default: 0

    reuse_tree::Bool:
        If this is true, the tree information is re-used for calculating the next plan.
        Of course, clear_tree! can always be called to override this.
        default: false

    enable_tree_vis::Bool:
        If this is true, extra information needed for tree visualization will
        be recorded. If it is false, the tree cannot be visualized.
        default: false
"""
mutable struct MCTSSolver <: AbstractMCTSSolver
	n_iterations::Int64
	depth::Int64
	exploration_constant::Float64
    rng::AbstractRNG
    estimate_value::Any
    init_Q::Any
    init_N::Any
    reuse_tree::Bool
    enable_tree_vis::Bool
end

"""
    MCTSSolver()

Use keyword arguments to specify values for the fields.
"""
function MCTSSolver(;n_iterations::Int64 = 100,
                     depth::Int64 = 10,
                     exploration_constant::Float64 = 1.0,
                     rng = Base.GLOBAL_RNG,
                     estimate_value = RolloutEstimator(RandomSolver(rng)),
                     init_Q = 0.0,
                     init_N = 0,
                     reuse_tree::Bool = false,
                     enable_tree_vis::Bool=false)
    return MCTSSolver(n_iterations, depth, exploration_constant, rng, estimate_value, init_Q, init_N, enable_tree_vis)
end

mutable struct MCTSPlanner{P<:Union{MDP,POMDP}, S, A, SE, RNG} <: AbstractMCTSPlanner{P}
	solver::MCTSSolver # containts the solver parameters
	mdp::P # model
    tree::Nullable{MCTSTree{S,A}} # the search tree
    solved_estimate::SE
    rng::RNG
end

function MCTSPlanner(solver::MCTSSolver, mdp::Union{POMDP,MDP})
    # tree = Dict{state_type(mdp), StateNode{action_type(mdp)}}()
    tree = MCTSTree{state_type(solver), action_type(solver)}(solver.n_iterations)
    se = convert_estimator(solver.estimate_value, solver, mdp)
    return MCTSPlanner(solver, mdp, Nullable(tree), se, solver.rng)
end


"""
Delete existing decision tree.
"""
function clear_tree!{S,A}(p::MCTSPlanner{S,A}) p.tree = Nullable{MCTSTree{S,A}}() end


# no computation is done in solve - the solver is just given the mdp model that it will work with
POMDPs.solve(solver::MCTSSolver, mdp::Union{POMDP,MDP}) = MCTSPlanner(solver, mdp)

@POMDP_require POMDPs.action(policy::AbstractMCTSPlanner, state) begin
    @subreq simulate(policy, state, policy.solver.depth)
end

function POMDPs.action(planner::AbstractMCTSPlanner, s)
    tree = build_tree(planner, state)
    planner.tree = Nullable(tree)
    best = best_id_Q(tree[state])
    return tree.a_labels[best]
end

function build_tree(planner::AbstractMCTSPlanner, state)
    n_iterations = planner.solver.n_iterations
    depth = planner.solver.depth
    
    if planner.solver.reuse_tree
        tree = planner.tree
    else
        tree = MCTSTree{state_type(planner.mdp), action_type(planner.mdp)}(n_iterations)
    end

    sid = get(tree.state_map, s, 0)
    if sid == 0
        root = insert_node!(tree, planner, s)
    else
        root = StateNode(tree, sid)
    end

    # build the tree
    for n = 1:n_iterations
        simulate(planner, root, depth)
    end
    return tree
end


function POMDPs.action(planner::AbstractMCTSPlanner, state, action)
    POMDPs.action(planner, state)
end

function simulate(planner::AbstractMCTSPlanner, node::StateNode, depth::Int64)
    mdp = planner.mdp
    rng = planner.rng
    s = state(node)
    tree = node.tree

    # once depth is zero return
    if depth == 0 || isterminal(planner.mdp, s)
        return 0.0
    end

    # pick action using UCT
    snode.N += 1 # increase number of node visits by one
    said = best_id_UCB(snode, planner.solver.exploration_constant)

    # transition to a new state
    sp, r = generate_sr(mdp, state, sanode.action, rng)
    
    if planner.solver.enable_tree_vis
        record_visit(planner, sanode, sp)
    end

    spid = get(tree.state_map, sp, 0)
    if spid == 0
        newnode = insert_node!(tree, planner, sp)
        q = r + discount(mdp) * estimate_value(planner.solved_estimate, planner.mdp, sp, depth - 1)
    else
        q = r + discount(mdp) * simulate(planner, StateNode(tree, spid) , depth - 1)
    end

    tree.n[said] += 1
    tree.q[said[ += ((q - tree.q[said]) / (tree.n[said])) # moving average of Q value
    return q
end

@POMDP_require simulate(planner::AbstractMCTSPlanner, state, depth::Int64) begin
    mdp = planner.mdp
    P = typeof(mdp)
    S = state_type(P)
    A = action_type(P)
    @req discount(::P)
    @req isterminal(::P, ::S)
    @subreq insert_node!(planner, state)
    @subreq estimate_value(planner.solved_estimate, mdp, state, depth)
    @req generate_sr(::P, ::S, ::A, ::typeof(planner.rng))
    @req isequal(::S, ::S) # for hasnode
    @req hash(::S) # for hasnode
end


# these functions are here so that they can be overridden by the aggregating solver
hasnode(planner::AbstractMCTSPlanner, s) = haskey(planner.tree, s)

function insert_node!(tree::MCTSTree, planner::MCTSPlanner, s)
    newnode = StateNode(planner, s)
    planner.tree[s] = newnode
    if planner.solver.enable_tree_vis
        for sanode in newnode.sanodes
            sanode._vis_stats = Set()
        end
    end
    return newnode
end

@POMDP_require insert_node!(planner::AbstractMCTSPlanner, s) begin
    # from the StateNode constructor
    P = typeof(planner.mdp)
    A = action_type(P)
    S = typeof(s)
    IQ = typeof(planner.solver.init_Q)
    if !(IQ <: Number) && !(IQ <: Function)
        @req init_Q(::IQ, ::P, ::S, ::A)
    end
    IN = typeof(planner.solver.init_N)
    if !(IN <: Number) && !(IN <: Function)
        @req init_N(::IN, ::P, ::S, ::A)
    end
    @req actions(::P, ::S)
    as = actions(planner.mdp, s)
    @req iterator(::typeof(as))
    @req isequal(::S, ::S) # for tree[s]
    @req hash(::S) # for tree[s]
end

getnode(policy::AbstractMCTSPlanner, s) = policy.tree[s]
record_visit(policy::AbstractMCTSPlanner, sanode::StateActionNode, s) = push!(get(sanode._vis_stats), s)

"""
Return the best action based on the Q score
"""
function best_sanode_Q(snode)
    best_Q = -Inf
    local best_sanode::StateActionNode
    for sanode in snode.sanodes
        if sanode.Q > best_Q
            best_Q = sanode.Q
            best_sanode = sanode
        end
    end
    return best_sanode
end

"""
Return the best action node based on the UCB score with exploration constant c
"""
function best_sanode_UCB(snode, c::Float64)
    best_UCB = -Inf
    best_sanode = snode.sanodes[1]
    sN = snode.N
    for sanode in snode.sanodes
        if (sN == 1 && sanode.N == 0) || c == 0.0
            UCB = sanode.Q
        else
            UCB = sanode.Q + c*sqrt(log(sN)/sanode.N)
        end
        @assert !isnan(UCB)
        @assert !isequal(UCB, -Inf)
        if UCB > best_UCB
            best_UCB = UCB
            best_sanode = sanode
        end
    end
    return best_sanode
end
