type StateNode
    n::Array{Int64,1}
    Q::Array{Reward,1}
    StateNode(nA) = new(zeros(Int32,nA),zeros(Reward,nA))
end

type MCTSSolver <: Solver
	n_interations::Int64			
	depth::Int64					
	discount_factor::Float64		
	exploration_constant::Float64	
    tree::Dict{State, StateNode}
end

function MCTSSolver(; n_interations::Int64 = 50, 
                      depth::Int64 = 20,
                      discount_factor::Float64 = 0.99,
                      exploration_constant::Float64 = 3.0)
    tree = Dict{State, StateNode}()
    return MCTSSolver(n_interations, depth, discount_factor, exploration_constant, tree)
end

type MCTSPolicy <: Policy
	mcts::MCTSSolver
	pomdp::POMDP
    action_map::Vector{Action}
    distribution::AbstractDistribution
end

function MCTSPolicy(mcts::MCTSSolver, pomdp::POMDP)
    am = Action[]
    space = actions(pomdp)
    for a in domain(space)
        push!(am, a)
    end
    d = create_transition(pomdp)
    return MCTSPolicy(mcts, pomdp, am, d)
end

#######################


function action(policy::MCTSPolicy, state::State)
    n_iterations = policy.mcts.n_interations
    depth = policy.mcts.depth

    for n = 1:n_iterations
        simulate(policy, state, depth)
    end

    return indmax(policy.mcts.tree[state].Q)
end

function simulate(policy::MCTSPolicy, state::State, depth::Int64)
    pomdp = policy.pomdp
    na = n_actions(pomdp)

    n_iterations = policy.mcts.n_interations
    discount_factor = policy.mcts.discount_factor
    tree = policy.mcts.tree
    exploration_constant = policy.mcts.exploration_constant

    if depth == 0
        return 0
    end

    if !haskey(tree, state)
        tree[state] = StateNode(na)
        return rollout(state, depth, policy)
    end 

    cS = tree[state]
    i = indmax(cS.Q + exploration_constant * real(sqrt(complex(log(sum(cS.n))./cS.n))))
    a = policy.action_map[i]
    d = policy.distribution
    transition!(d, pomdp, state, a)
    s_prime = rand(d)
    r = reward(pomdp, state, a)
    q = r + discount_factor * simulate(policy, s_prime, depth - 1)
    cS.n[i] += 1
    cS.Q[i] += ((q - cS.Q[i]) / (cS.n[i]))
    return q
end

function rollout(state::State, depth::Depth, policy::MCTSPolicy)
    pomdp = policy.pomdp
    discount_factor = policy.mcts.discount_factor
    
    if depth == 0
        return 0.0
    end

    action_space = actions(pomdp)
    actions!(action_space, pomdp, state)
    a = rand(action_space)
    d = policy.distribution
    transition!(d, pomdp, state, a)
    s_prime = rand(d)
    r = reward(pomdp, state, a)

    return (r + (discount_factor) * rollout(s_prime, depth - 1, policy))
end 
