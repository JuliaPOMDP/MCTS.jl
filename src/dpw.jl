function POMDPs.solve(solver::DPWSolver, mdp::Union{POMDP,MDP}, p::DPWPolicy=DPWPolicy(solver, mdp))
    p.solved_estimate = convert_estimator(p.solver.estimate_value, solver, mdp)
    return p
end

"""
Delete existing decision tree.
"""
function clear_tree!{S,A}(p::DPWPolicy{S,A}) p.tree = Dict{S, DPWStateNode{S,A}}() end

"""
Call simulate and chooses the approximate best action from the reward approximations
"""
function POMDPs.action{S,A}(p::DPWPolicy{S,A}, s::S, a::A=create_action(p.mdp))
    for i = 1:p.solver.n_iterations
        simulate(p, deepcopy(s), p.solver.depth) # (not 100% sure we need to make a copy of the state here)
    end
    snode = p.tree[s]
    best_Q = -Inf
    local best_a
    for (a, sanode) in snode.A
        if sanode.Q > best_Q
            best_Q = sanode.Q
            best_a = a
        end
    end
    # XXX some publications say to choose action that has been visited the most
    return best_a # choose action with highest approximate value 
end

"""
Return the reward for one iteration of MCTSDPW.
"""
function simulate{S,A}(dpw::DPWPolicy{S,A}, s::S, d::Int)
    if d == 0 || isterminal(dpw.mdp, s)
        return 0.0
    end
    if !haskey(dpw.tree,s) # if state is not yet explored, add it to the set of states, perform a rollout 
        dpw.tree[s] = DPWStateNode{S,A}()
        dpw.tree[s].N += 1
        return estimate_value(dpw.solved_estimate, dpw.mdp, s, d)
    end

    snode = dpw.tree[s] # save current state node so we do not have to iterate through map many times
    snode.N = snode.N + 1

    # action progressive widening
    if length(snode.A) <= dpw.solver.k_action*snode.N^dpw.solver.alpha_action # criterion for new action generation
        a = next_action(dpw.solver.next_action, dpw.mdp, s, snode) # action generation step
        if !haskey(snode.A,a) # make sure we haven't already tried this action
            snode.A[a] = DPWStateActionNode{S}(init_N(dpw.solver.init_N, dpw.mdp, s, a),
                                               init_Q(dpw.solver.init_Q, dpw.mdp, s, a))
        end
    end

    best_UCB = -Inf
    local a
    sN = snode.N
    for (act, sanode) in snode.A
        if sN == 1 && sanode.N == 0
            UCB = sanode.Q
        else
            c = dpw.solver.exploration_constant # for clarity
            UCB = sanode.Q + c*sqrt(log(sN)/sanode.N)
        end
        @assert !isnan(UCB)
        @assert !isequal(UCB, -Inf)
        if UCB > best_UCB
            best_UCB = UCB
            a = act
        end
    end

    sanode = snode.A[a]

    # state progressive widening
    if length(sanode.V) <= dpw.solver.k_state*sanode.N^dpw.solver.alpha_state # criterion for new transition state consideration
        sp, r = generate_sr(dpw.mdp, s, a, dpw.solver.rng) # choose a new state and get reward

        if !haskey(sanode.V,sp) # if transition state not yet explored, add to set and update reward
            sanode.V[sp] = StateActionStateNode()
            sanode.V[sp].R = r
        end
        sanode.V[sp].N += 1

    else # sample from transition states proportional to their occurence in the past
        # warn("sampling states: |V|=$(length(sanode.V)), N=$(sanode.N)")
        total_N = reduce(add_N, 0, values(sanode.V))
        rn = rand(dpw.solver.rng, 1:total_N)
        cnt = 0
        local sp, sasnode
        for (sp,sasnode) in sanode.V
            cnt += sasnode.N
            if rn <= cnt
                break
            end
        end

        r = sasnode.R
    end

    q = r + discount(dpw.mdp)*simulate(dpw,sp,d-1)

    sanode.N += 1

    sanode.Q += (q - sanode.Q)/sanode.N

    return q
end

"""
Add the N's of two sas nodes - for use in reduce
"""
add_N(a::StateActionStateNode, b::StateActionStateNode) = a.N + b.N
add_N(a::Int, b::StateActionStateNode) = a + b.N
