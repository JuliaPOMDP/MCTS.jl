function POMDPs.solve(solver::DPWSolver, mdp::Union{POMDP,MDP})
    S = state_type(mdp)
    A = action_type(mdp)
    se = convert_estimator(solver.estimate_value, solver, mdp)
    return DPWPlanner(solver, mdp, Nullable{DPWTree{S,A}}(), se, solver.next_action, solver.rng)
end

"""
Delete existing decision tree.
"""
function clear_tree!(p::DPWPlanner)
    p.tree = Nullable()
end

"""
Construct an MCTSDPW tree and choose the best action.
"""
POMDPs.action(p::DPWPlanner, s) = first(action_info(p, s))

"""
Construct an MCTSDPW tree and choose the best action. Also output some information.
"""
function POMDPToolbox.action_info(p::DPWPlanner, s; tree_in_info=false)
    local a::action_type(p.mdp)
    info = Dict{Symbol, Any}()
    try
        if isterminal(p.mdp, s)
            error("""
                  MCTS cannot handle terminal states. action was called with
                  s = $s
                  """)
        end

        S = state_type(p.mdp)
        A = action_type(p.mdp)
        if p.solver.keep_tree
            if isnull(p.tree)
                tree = DPWTree{S,A}(p.solver.n_iterations)
                p.tree = Nullable(tree)
            else
                tree = get(p.tree)
            end
            if haskey(tree.s_lookup, s)
                snode = tree.s_lookup[s]
            else
                snode = insert_state_node!(tree, s, true)
            end
        else
            tree = DPWTree{S,A}(p.solver.n_iterations)
            p.tree = Nullable(tree)
            snode = insert_state_node!(tree, s, p.solver.check_repeat_state)
        end

        i = 0
        start_us = CPUtime_us()
        for i = 1:p.solver.n_iterations
            simulate(p, snode, p.solver.depth) # (not 100% sure we need to make a copy of the state here)
            if CPUtime_us() - start_us >= p.solver.max_time * 1e6
                break
            end
        end
        info[:search_time_us] = CPUtime_us() - start_us
        info[:tree_queries] = i
        if p.solver.tree_in_info || tree_in_info
            info[:tree] = tree
        end
        
        best_Q = -Inf
        sanode = 0
        for child in tree.children[snode]
            if tree.q[child] > best_Q
                best_Q = tree.q[child]
                sanode = child
            end
        end
        # XXX some publications say to choose action that has been visited the most
        a = tree.a_labels[sanode] # choose action with highest approximate value
    catch ex
        a = convert(action_type(p.mdp), default_action(p.solver.default_action, p.mdp, s, ex))
        info[:exception] = ex
    end

    return a, info
end


"""
Return the reward for one iteration of MCTSDPW.
"""
function simulate(dpw::DPWPlanner, snode::Int, d::Int)
    S = state_type(dpw.mdp)
    A = action_type(dpw.mdp)
    sol = dpw.solver
    tree = get(dpw.tree)
    s = tree.s_labels[snode]
    if d == 0 || isterminal(dpw.mdp, s)
        return 0.0
    end

    # action progressive widening
    if dpw.solver.enable_action_pw
        if length(tree.children[snode]) <= sol.k_action*tree.total_n[snode]^sol.alpha_action # criterion for new action generation
            a = next_action(dpw.next_action, dpw.mdp, s, DPWStateNode(tree, snode)) # action generation step
            if !sol.check_repeat_action || !haskey(tree.a_lookup, (snode, a))
                n0 = init_N(sol.init_N, dpw.mdp, s, a)
                insert_action_node!(tree, snode, a, n0,
                                    init_Q(sol.init_Q, dpw.mdp, s, a),
                                    sol.check_repeat_action
                                   )
                tree.total_n[snode] += n0
            end
        end
    elseif isempty(tree.children[snode])
        for a in iterator(actions(dpw.mdp, s))
            n0 = init_N(sol.init_N, dpw.mdp, s, a)
            insert_action_node!(tree, snode, a, n0,
                                init_Q(sol.init_Q, dpw.mdp, s, a),
                                false)
            tree.total_n[snode] += n0
        end
    end

    best_UCB = -Inf
    sanode = 0
    ltn = log(tree.total_n[snode])
    for child in tree.children[snode]
        n = tree.n[child]
        q = tree.q[child]
        c = sol.exploration_constant # for clarity
        if (ltn <= 0 && n == 0) || c == 0.0
            UCB = q
        else
            UCB = q + c*sqrt(ltn/n)
        end
        @assert !isnan(UCB) "UCB was NaN (q=$q, c=$c, ltn=$ltn, n=$n)"
        @assert !isequal(UCB, -Inf)
        if UCB > best_UCB
            best_UCB = UCB
            sanode = child
        end
    end

    a = tree.a_labels[sanode]

    # state progressive widening
    new_node = false
    if tree.n_a_children[sanode] <= sol.k_state*tree.n[sanode]^sol.alpha_state
        sp, r = generate_sr(dpw.mdp, s, a, dpw.rng)

        spnode = sol.check_repeat_state ? get(tree.s_lookup, sp, 0) : 0

        if spnode == 0 # there was not a state node for sp already in the tree
            spnode = insert_state_node!(tree, sp, sol.keep_tree || sol.check_repeat_state)
            new_node = true
        end
        push!(tree.transitions[sanode], (spnode, r))

        if !sol.check_repeat_state 
            tree.n_a_children[sanode] += 1
        elseif !((sanode,spnode) in tree.unique_transitions)
            push!(tree.unique_transitions, (sanode,spnode))
            tree.n_a_children[sanode] += 1
        end
    else
        spnode, r = rand(dpw.rng, tree.transitions[sanode])
    end

    if new_node
        q = r + discount(dpw.mdp)*estimate_value(dpw.solved_estimate, dpw.mdp, sp, d-1)
    else
        q = r + discount(dpw.mdp)*simulate(dpw, spnode, d-1)
    end

    tree.n[sanode] += 1
    tree.total_n[snode] += 1

    tree.q[sanode] += (q - tree.q[sanode])/tree.n[sanode]

    return q
end
