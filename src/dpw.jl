type DPWSolver
    depth::Int                       # search depth
    exploration_constant::Float64    # exploration constant- governs trade-off between exploration and exploitation in MCTS
    n_iterations::Int                # number of iterations
    k_action::Float64                # first constant controlling action generation
    alpha_action::Float64            # second constant controlling action generation
    k_state::Float64                 # first constant controlling transition state generation
    alpha_state::Float64             # second constant controlling transition state generation
    rng::AbstractRNG
    rollout_solver::Union{Policy,Solver}
end

type StateActionStateNode
    N::Int
    R::Float64
    StateActionStateNode() = new(0,0)
end

type StateActionNode
    V::Dict{State,StateActionStateNode}
    N::Int
    Q::Float64
    StateActionNode() = new(Dict{State,StateActionStateNode}(),0,0)
end

type StateNode
    A::Dict{Action,StateActionNode}
    N::Int
    StateNode() = new(Dict{Action,StateActionNode}(),0)
end

type DPWPolicy
    solver::DPWSolver
    mdp::POMDP
    T::Dict{State,StateNode} 
    _action_space::AbstractSpace
    DPWPolicy(solver::DPWSolver, mdp::POMDP) = new(solver, mdp, Dict{State,StateNode}(), actions(mdp))
end

function action(p::DPWPolicy, s::State, a::Action=create_action(p.mdp))
    # This function calls simulate and chooses the approximate best action from the reward approximations
    for i = 1:dpw.solver.n_iterations
        simulate(dpw, s, dpw.solver.depth)
    end
    snode = dpw.T[s]
    best_Q = -Inf
    local best_a
    for (a, sanode) in snode.A
        if sanode.Q > best_Q
            best_Q = sanode.Q
            best_a = a
        end
    end
    # XXX some publications say to choose action that has been visited the most
    return a # choose action with highest approximate value 
end

function simulate(dpw::DPWPolicy,s::State,d::Depth)
    # TODO: reimplement this as a loop instead of a recursion

    # This function returns the reward for one iteration of MCTSdpw 
    if d == 0
        return 0.0 # XXX is this right or should it be a rollout?
    end
    if !haskey(dpw.T,s) # if state is not yet explored, add it to the set of states, perform a rollout 
        dpw.T[s] = StateNode() # TODO: Mechanism to set N0
        return estimate_value(dpw,s,d)
    end

    snode = dpw.T[s] # save current state node so we do not have to iterate through map many times
    snode.N = snode.N + 1

    # action progressive widening
    if length(dpw.T[s].A) <= dpw.solver.k_action*dpw.T[s].N^dpw.solver.alpha_action # criterion for new action generation
        a = next_action(dpw.mdp, snode) # action generation step
        if !haskey(dpw.T[s].A,a) # make sure we haven't already tried this action
            dpw.T[s].A[a] = StateActionNode() # TODO: Mechanism to set N0, Q0
        end
    else # choose an action using UCB criterion
        best_UCB = -Inf
        local a
        sN = snode.N
        for act in keys(snode.A)
            sanode = snode.A[act]
            if sN == 1 && sanode.N == 0
                UCB = sanode.Q
            else
                c = dpw.solver.exploration_constant # for clarity
                UCB = sanode.Q + c*sqrt(log(sN)/sanode.N)
            end
            if UCB > best_UCB
                best_UCB = UCB
                a = act
            end
        end
    end

    sanode = snode.A[a]

    # state progressive widening
    if length(sanode.V) <= dpw.solver.k_state*sanode.N^dpw.solver.alpha_state # criterion for new transition state consideration
        sp, r = generate(dpw.mdp, s, a, dpw.solver.rng) # choose a new state and get reward

        if !haskey(sanode.V,sp) # if transition state not yet explored, add to set and update reward
            sanode.V[sp] = StateActionStateNode() # TODO: mechanism for assigning N0
            sanode.V[sp].R = r
        else
            sanode.V[sp].N += 1
        end
    else # sample from transition states proportional to their occurence in the past
        rn = rand(dpw.solver.rng, 1:sanode.N)
        cnt = 0
        local sp
        for (sp,sasnode) in values(sanode.V)
            cnt += sasnode.N
            if rn <= cnt
                break
            end
        end

        r = sasnode.R
        sasnode.N += 1
    end

    q = r + discount(dpw.mdp)*simulate(dpw,sp,d-1)

    sanode.N += 1
    sanode.Q += (q - sanode.Q)/sanode.N

    return q
end

# this can be overridden to specify behavior; by default it performs a rollout
function estimate_value(dpw::DPWPolicy, s::State, d::Int)
    rollout(dpw, s, d)
end

function rollout(dpw::DPWPolicy, s::State, d::Int)
    sim = MDPRolloutSimulator(rng=dpw.solver.rng, max_steps=d) # TODO(?) add a mechanism to customize this
    simulate(sim, dpw.mdp, dpw.rollout_policy, s)
end

function next_action(dpw::DPWPolicy, mdp::POMDP, s::StateNode)
    rand(rng, actions(mdp, s, dpw._action_space))
end
