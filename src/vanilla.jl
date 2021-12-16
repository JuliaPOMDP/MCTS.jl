"""
MCTS solver type

Fields:

    n_iterations::Int64
        Number of iterations during each action() call.
        default: 100

    max_time::Float64
        Maximum amount of CPU time spent iterating through simulations.
        default: Inf

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

    virtual_loss::Float64:
        A temporary loss added to the UCB score for nodes that are currently being
        evaluated by some threads. This can be used to encourage threads to explore
        broader parts of the search space. Relevant when running MCTS with multiple threads.
        default: 0.0

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
    max_time::Float64
    depth::Int64
    exploration_constant::Float64
    rng::AbstractRNG
    estimate_value::Any
    init_Q::Any
    init_N::Any
    virtual_loss::Float64
    reuse_tree::Bool
    enable_tree_vis::Bool
end

"""
    MCTSSolver()

Use keyword arguments to specify values for the fields.
"""
function MCTSSolver(;n_iterations::Int64=100,
                     max_time::Float64=Inf,
                     depth::Int64=10,
                     exploration_constant::Float64=1.0,
                     rng=Random.GLOBAL_RNG,
                     estimate_value=RolloutEstimator(RandomSolver(rng)),
                     init_Q=0.0,
                     init_N=0,
                     virtual_loss::Float64=0.0,
                     reuse_tree::Bool=false,
                     enable_tree_vis::Bool=false)
    return MCTSSolver(n_iterations, max_time, depth, exploration_constant, rng,
                      estimate_value, init_Q, init_N, virtual_loss, reuse_tree,
                      enable_tree_vis)
end


mutable struct ActionNode{A}
    id::Int
    a_label::A
    n::Int
    q::Float64
end
ActionNode(id::Int, a::A, n::Int, q::Float64) where A = ActionNode{A}(id, a, n, q)

# Accessors for action nodes
@inline POMDPs.action(n::ActionNode) = n.a_label
@inline n(n::ActionNode) = n.n
@inline q(n::ActionNode) = n.q


mutable struct StateNode{S,A}
    id::Int
    s_label::S
    total_n::Int
    child_nodes::Vector{ActionNode{A}}
    s_lock::ReentrantLock
    # Action nodes currently being evaluated. Used for applying virtual loss.
    a_selected::Set{A}
end
StateNode(id::Int, s::S, total_n::Int, a_nodes::Vector{ActionNode{A}}) where {S,A} =
    StateNode{S,A}(id, s, total_n, a_nodes, ReentrantLock(), Set{A}())

# Accessors for state nodes
@inline state(n::StateNode) = n.s_label
@inline total_n(n::StateNode) = n.total_n
@inline children(n::StateNode) = n.child_nodes


mutable struct MCTSTree{S,A}
    root::Union{Nothing, S}
    states::Dict{S, StateNode}

    # Maps (said=>sid)=>number of transitions. THIS MAY CHANGE IN THE FUTURE
    _vis_stats::Union{Nothing, Dict{Pair{Int,Int}, Int}}
    _s_id_counter::Threads.Atomic{Int}
    _a_id_counter::Threads.Atomic{Int}

    # Locks and others needed for multithreaded MCTS.
    # TODO(kykim): Also support a lock-free approach.
    states_lock::ReentrantLock
    vis_stats_lock::ReentrantLock

    function MCTSTree{S,A}(root::Union{Nothing, S}=nothing) where {S,A}
        return new(root,
                   Dict{S, StateNode}(),

                   Dict{Pair{Int,Int},Int}(),
                   Threads.Atomic{Int}(1),
                   Threads.Atomic{Int}(1),

                   ReentrantLock(),
                   ReentrantLock())
    end
end

Base.isempty(t::MCTSTree) = isempty(t.states)
state_nodes(t::MCTSTree) = values(t.states)

"""
    get_state_node(tree::MCTSTree, s)

Return the StateNode in the tree corresponding to s.
"""
get_state_node(tree::MCTSTree, s) = tree.states[s]


mutable struct MCTSPlanner{P<:Union{MDP,POMDP}, S, A, SE, RNG} <: AbstractMCTSPlanner{P}
    solver::MCTSSolver # contains the solver parameters
    mdp::P # model
    tree::Union{Nothing,MCTSTree{S,A}} # the search tree
    solved_estimate::SE
    rng::RNG
end


function MCTSPlanner(solver::MCTSSolver, mdp::Union{POMDP,MDP})
    tree = MCTSTree{statetype(mdp), actiontype(mdp)}()
    se = convert_estimator(solver.estimate_value, solver, mdp)
    return MCTSPlanner(solver, mdp, tree, se, solver.rng)
end


"""
Delete existing decision tree.
"""
function clear_tree!(p::MCTSPlanner{S,A}) where {S,A} p.tree = nothing end

"""
    get_state_node(tree::MCTSTree, s, planner::MCTSPlanner)

Return the StateNode in the tree corresponding to s. If there is no such node, add it using the planner.
"""
function get_state_node(tree::MCTSTree, s, planner::MCTSPlanner)
    if haskey(tree.states, s)
        return tree.states[s]
    else
        return insert_node!(tree, planner, s)
    end
end


# No computation is done in solve - the solver is just given the mdp model that it will work with
POMDPs.solve(solver::MCTSSolver, mdp::Union{POMDP,MDP}) = MCTSPlanner(solver, mdp)

@POMDP_require POMDPs.action(policy::AbstractMCTSPlanner, state) begin
    @subreq simulate(policy, policy.tree, state, policy.solver.depth)
end

function POMDPModelTools.action_info(p::AbstractMCTSPlanner, s)
    tree = plan!(p, s)
    best = best_sanode_Q(tree.states[s])
    return action(best), (tree=tree,)
end

POMDPs.action(p::AbstractMCTSPlanner, s) = first(action_info(p, s))

"""
Query the tree for a value estimate at state s. If the planner does not already have a tree, run the planner first.
"""
function POMDPs.value(planner::MCTSPlanner, s)
    if planner.tree == nothing
        plan!(planner, s)
    end
    return value(planner.tree, s)
end


function POMDPs.value(tree::MCTSTree, s)
    snode = get(tree.states, s, nothing)
    if snode == nothing
        error("State $s not present in MCTS tree.")
    end
    return maximum(q(san) for san in children(snode))
end


function POMDPs.value(planner::MCTSPlanner{<:Union{POMDP,MDP}, S, A}, s::S, a::A) where {S,A}
    if planner.tree == nothing
        plan!(planner, s)
    end
    return value(planner.tree, s, a)
end


function POMDPs.value(tree::MCTSTree{S,A}, s::S, a::A) where {S,A}
    for san in children(tree.states[s]) # slow search through children
        if action(san) == a
            return q(san)
        end
    end
end


"""
Build tree and store it in the planner.
"""
function plan!(planner::AbstractMCTSPlanner, s)
    tree = build_tree(planner, s)
    planner.tree = tree
    return tree
end


function build_tree(planner::AbstractMCTSPlanner, s)
    n_iterations = planner.solver.n_iterations
    depth = planner.solver.depth

    if planner.solver.reuse_tree
        tree = planner.tree
    else
        tree = MCTSTree{statetype(planner.mdp), actiontype(planner.mdp)}(s)
    end

    root = get(tree.states, s, nothing)
    if root == nothing
        root = insert_node!(tree, planner, s)
    end

    timeout_us = CPUtime_us() + planner.solver.max_time * 1e6
    # Run simulation in a sequential manner in case of single thread. The
    # Channel approach below seems more efficient only if multiple threads are
    # used. This is presumably due that in case of single thread a lot of time
    # can be wasted context switching between the producer and consumer.
    if Threads.nthreads() == 1
        for n in 1:n_iterations
            simulate(planner, tree, root, depth)
            CPUtime_us() > timeout_us && break
        end
        return tree
    end

    # Use a Channel to implement a producer-consumer type interaction. This
    # seems quite crucial for performance in case of multiple threads.
    # TODO(kykim): See if the two cases can be more concisely combined.
    sim_channel = Channel{Task}(min(1000, n_iterations)) do channel
        for n in 1:n_iterations
            put!(channel, Threads.@spawn simulate(planner, tree, root, depth, timeout_us))
        end
    end
    for sim_task in sim_channel
        CPUtime_us() > timeout_us && break
        try
            fetch(sim_task)  # Throws a TaskFailedException if failed.
        catch err
            throw(err.task.exception)  # Throw the underlying exception.
        end
    end
    return tree
end


function simulate(planner::AbstractMCTSPlanner, tree::MCTSTree, snode::StateNode, depth::Int64, timeout_us::Float64=0.0)
    mdp = planner.mdp
    rng = planner.rng
    s = state(snode)
    solver = planner.solver

    # Once depth is zero return.
    if isterminal(planner.mdp, s)
        return 0.0
    elseif depth == 0 || (timeout_us > 0.0 && CPUtime_us() > timeout_us)
        return estimate_value(planner.solved_estimate, planner.mdp, s, depth)
    end

    # Pick action using UCT.
    sanode = run_optlock(() -> best_sanode_UCB(snode, solver.exploration_constant, solver.virtual_loss), snode.s_lock)

    # Transition to a new state.
    sp, r = @gen(:sp, :r)(mdp, s, action(sanode), rng)

    spnode = run_optlock(() -> get(tree.states, sp, nothing), tree.states_lock)
    if spnode == nothing
        spnode = insert_node!(tree, planner, sp)
        q = r + discount(mdp) * estimate_value(planner.solved_estimate, planner.mdp, sp, depth - 1)
    else
        q = r + discount(mdp) * simulate(planner, tree, spnode, depth - 1, timeout_us)
    end
    if solver.enable_tree_vis
        run_optlock(() -> record_visit!(tree, sanode.id, spnode.id), tree.vis_stats_lock)
    end

    function backpropagate(snode::StateNode, sanode::ActionNode, q::Float64)
        snode.total_n += 1
        sanode.n += 1
        sanode.q = (q - sanode.q) / sanode.n  # Moving average of Q value
        delete!(snode.a_selected, sanode.a_label)
    end
    run_optlock(() -> backpropagate(snode, sanode, q), snode.s_lock)

    return q
end


@POMDP_require simulate(planner::AbstractMCTSPlanner, tree::MCTSTree, s, depth::Int64, timeout_us::Float64) begin
    mdp = planner.mdp
    P = typeof(mdp)
    S = statetype(P)
    A = actiontype(P)
    @req discount(::P)
    @req isterminal(::P, ::S)
    @subreq insert_node!(planner.tree, planner, s)
    @subreq estimate_value(planner.solved_estimate, mdp, s, depth)
    @req gen(::P, ::S, ::A, ::typeof(planner.rng)) # XXX this is not exactly right - it could be satisfied with transition
    @req isequal(::S, ::S) # for hasnode
    @req hash(::S) # for hasnode
end


function insert_node!(tree::MCTSTree, planner::MCTSPlanner, s)
    total_n = 0
    A = actiontype(typeof(planner.mdp))
    a_nodes = Vector{ActionNode{A}}()
    for a in actions(planner.mdp, s)
        n = init_N(planner.solver.init_N, planner.mdp, s, a)
        q = init_Q(planner.solver.init_Q, planner.mdp, s, a)
        total_n += n
        a_node = ActionNode(Threads.atomic_add!(tree._a_id_counter, 1), a, n, q)
        push!(a_nodes, a_node)
    end
    snode = StateNode(Threads.atomic_add!(tree._s_id_counter, 1), s, total_n, a_nodes)
    run_optlock(() -> tree.states[s] = snode, tree.states_lock)
    return snode
end


@POMDP_require insert_node!(tree::MCTSTree, planner::AbstractMCTSPlanner, s) begin
    # From the StateNode constructor
    P = typeof(planner.mdp)
    A = actiontype(P)
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
    @req isequal(::S, ::S) # for tree[s]
    @req hash(::S) # for tree[s]
end


function record_visit!(tree::MCTSTree, said::Int, spid::Int)
    vs = tree._vis_stats
    if !haskey(vs, said=>spid)
        vs[said=>spid] = 0
    end
    vs[said=>spid] += 1
end


"""
Return the best action based on the Q score
"""
function best_sanode_Q(snode::StateNode)
    best_Q = -Inf
    best = first(children(snode))
    for sanode in children(snode)
        if q(sanode) > best_Q
            best_Q = q(sanode)
            best = sanode
        end
    end
    return best
end


"""
Return the best action node based on the UCB score with exploration constant c
"""
function best_sanode_UCB(snode::StateNode, c::Float64, virtual_loss::Float64=0.0)
    best_UCB = -Inf
    best = first(children(snode))
    sn = total_n(snode)
    for sanode in children(snode)
        # if sn==0, log(sn) = -Inf. We want to avoid this.
        # in most cases, if n(sanode)==0, UCB will be Inf, which is desired,
        # but if sn==1 as well, then we have 0/0, which is NaN
        if c == 0 || sn == 0 || (sn == 1 && n(sanode) == 0)
            UCB = q(sanode)
        else
            vloss = 0.0
            if virtual_loss > 0.0 && sanode.a_label in snode.a_selected
                vloss = virtual_loss
            end
            UCB = q(sanode) + c*sqrt(log(sn)/n(sanode)) - vloss
        end

        if isnan(UCB)
            @show sn
            @show n(sanode)
            @show q(sanode)
        end

        @assert !isnan(UCB)
        @assert !isequal(UCB, -Inf)

        if UCB > best_UCB
            best_UCB = UCB
            best = sanode
        end
    end
    run_optlock(() -> push!(snode.a_selected, best.a_label), snode.s_lock)
    return best
end


"""
Run a given function optionally with a lock.
"""
@inline run_optlock(f::Function, lk::Base.AbstractLock) = Threads.nthreads() == 1 ? f() : lock(f, lk)
