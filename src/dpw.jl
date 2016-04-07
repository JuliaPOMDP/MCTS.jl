function POMDPs.solve(solver::DPWSolver, mdp::PermissiveMDP, p::DPWPolicy=DPWPolicy(solver, mdp))
    if isa(p.solver.rollout_solver, Solver) 
        p.rollout_policy = solve(p.solver.rollout_solver, mdp)
    else
        p.rollout_policy = p.solver.rollout_solver
    end
    return p
end

function POMDPs.action{S,A}(p::DPWPolicy{S,A}, s::S, a::A=A())
    # This function calls simulate and chooses the approximate best action from the reward approximations
    # XXX do we need to make a copy of the state here?
    for i = 1:p.solver.n_iterations
        simulate(p, deepcopy(s), p.solver.depth)
    end
    snode = p.T[s]
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

function simulate{S,A}(dpw::DPWPolicy{S,A}, s::S, d::Int)
    # TODO: reimplement this as a loop instead of a recursion?

    # This function returns the reward for one iteration of MCTSdpw 
    if d == 0 || isterminal(dpw.mdp, s)
        return 0.0 # XXX is this right or should it be a rollout?
    end
    if !haskey(dpw.T,s) # if state is not yet explored, add it to the set of states, perform a rollout 
        dpw.T[s] = DPWStateNode{S,A}() # TODO: Mechanism to set N0
        return estimate_value(dpw,s,d)
    end

    snode = dpw.T[s] # save current state node so we do not have to iterate through map many times
    snode.N = snode.N + 1

    # action progressive widening
    if length(snode.A) <= dpw.solver.k_action*snode.N^dpw.solver.alpha_action # criterion for new action generation
        a = next_action(dpw.solver.action_generator, dpw.mdp, s, snode) # action generation step
        if !haskey(snode.A,a) # make sure we haven't already tried this action
            snode.A[a] = DPWStateActionNode{S}() # TODO: Mechanism to set N0, Q0
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
        sp, r = generate(dpw.mdp, s, a, dpw.solver.rng) # choose a new state and get reward

        if !haskey(sanode.V,sp) # if transition state not yet explored, add to set and update reward
            sanode.V[sp] = StateActionStateNode() # TODO: mechanism for assigning N0
            sanode.V[sp].R = r
        end
        sanode.V[sp].N += 1

        # XXX this differs from Mykel's writeup. is it ok?
        sanode.N += 1

    else # sample from transition states proportional to their occurence in the past
        # warn("sampling states: |V|=$(length(sanode.V)), N=$(sanode.N)")
        rn = rand(dpw.solver.rng, 1:sanode.N) # this is where Jon's bug was (I think)
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

    sanode.Q += (q - sanode.Q)/sanode.N

    return q
end

# this can be overridden to specify behavior; by default it performs a rollout
function estimate_value(dpw::DPWPolicy, s, d::Int)
    rollout(dpw, s, d)
end

function rollout(dpw::DPWPolicy, s, d::Int)
    sim = MDPRolloutSimulator(rng=dpw.solver.rng, max_steps=d) # TODO(?) add a mechanism to customize this
    POMDPs.simulate(sim, dpw.mdp, dpw.rollout_policy, s)
end
