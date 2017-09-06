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
Call simulate and chooses the approximate best action from the reward approximations
"""
function POMDPs.action(p::DPWPlanner, s)
    start_us = CPUtime_us()
    S = state_type(p.mdp)
    A = action_type(p.mdp)
    if p.solver.keep_tree
        tree = get(p.tree, DPWTree{S,A}(p.solver.n_iterations))
        if haskey(p.tree.s_lookup, s)
            snode = p.tree.s_lookup[s]
        else
            snode = insert_state_node!(get(p.tree), s, sol.keep_tree || sol.check_repeat_state)
        end
    else
        tree = DPWTree{S,A}(p.solver.n_iterations)
        p.tree = Nullable(tree)
        snode = insert_state_node!(tree, s, p.solver.check_repeat_state)
    end
    for i = 1:p.solver.n_iterations
        simulate(p, snode, p.solver.depth) # (not 100% sure we need to make a copy of the state here)
        if CPUtime_us() - start_us >= p.solver.max_time * 1e6
            break
        end
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
    return tree.a_labels[sanode] # choose action with highest approximate value 
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

    best_UCB = -Inf
    sanode = 0
    ltn = log(tree.total_n[snode])
    for child in tree.children[snode]
        n = tree.n[child]
        q = tree.q[child]
        if ltn <= 0 && n == 0
            UCB = q
        else
            c = sol.exploration_constant # for clarity
            UCB = q + c*sqrt(ltn/n)
        end
        @assert !isnan(UCB)
        @assert !isequal(UCB, -Inf)
        if UCB > best_UCB
            best_UCB = UCB
            sanode = child
        end
    end

    a = tree.a_labels[sanode]

    # state progressive widening
    if length(tree.transitions[sanode]) <= sol.k_state*tree.n[sanode]^sol.alpha_state

        sp, r = generate_sr(dpw.mdp, s, a, dpw.rng)

        if sol.check_repeat_state
            spnode = get(tree.s_lookup, sp, 0)
        else
            spnode = 0
        end

        if spnode == 0 # there was not a state node for sp already in the tree
            spnode = insert_state_node!(tree, sp, sol.keep_tree || sol.check_repeat_state)
        end
        push!(tree.transitions[sanode], (spnode, r))

        if tree.total_n[spnode] == 0
            return r + estimate_value(dpw.solved_estimate, dpw.mdp, sp, d-1)
        end
    else
        (spnode, r) = rand(dpw.rng, tree.transitions[sanode])
    end

    q = r + discount(dpw.mdp)*simulate(dpw, spnode, d-1)

    tree.n[sanode] += 1
    tree.total_n[snode] += 1

    tree.q[sanode] += (q - tree.q[sanode])/tree.n[sanode]

    return q
end
