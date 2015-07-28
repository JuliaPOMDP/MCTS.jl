
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
                      exploration_constant::Float64 = 1.0)
    tree = Dict{State, StateNode}()
    return MCTSSolver(n_interations, depth, discount_factor, exploration_constant, tree)
end

type MCTSPolicy <: Policy
	mcts::MCTSSolver
	pomdp::POMDP
    action_map::Vector{Action}
end

function MCTSPolicy(mcts::MCTSSolver, pomdp::POMDP)
    am = Action[]
    space = actions(pomdp)
    for a in domain(space)
        push!(am, a)
    end
    return MCTSPolicy(mcts, pomdp, am)
end

#######################


function action(policy::MCTSPolicy, state::State)
    n_iterations = policy.mcts.n_interations

    for n = 1:n_iterations
        simulate(state, depth)
    end

    return indmax(policy.mcts.tree[state].Q)
end

function simulate(policy::MCTSPolicy, state::State)
    pomdp = policy.pomdp
    na = n_actions(pomdp)

    n_iterations = policy.mcts.n_interations
    depth = policy.mcts.depth
    discount_factor = policy.mcts.discount_factor
    tree = policy.mcts.tree
    exploration_constant = policy.mcts.exploration_constant
    matrix = policy.mcts.M 

    if depth == 0
        return 0
    end

    if !haskey(tree, state)
        tree[state] = StateNode(na)
        return rollout(state::State, depth::Depth)
    end 

    cS = tree[state]
    i = indmax(cS.Q + exploration_constant * real(sqrt(complex(log(sum(cS.n))/cS.n))))
    a = policy.action_map[i]
    transition!(depth, pomdp, state, a)
    s_prime = rand(d)
    reward = reward(pomdp, state, a)
    q = reward + discount_factor * simulate(s_prime, depth - 1)
    cS.n[i] += 1
    cS.q[i] += ((q - cS.q[i]) / (cS.n[i]))
    return q
end

function rollout(state::State, depth::Depth, policy::MCTSPolicy)
    pomdp = policy.pomdp
    depth = policy.mcts.depth
    discount_factor = policy.mcts.discount_factor
    
    if depth == 0
        return 0
    end
    action_space = actions(pomdp, state)
    actions!(action_space, pomdp, state)
    a = rand(action_space)

    transition!(depth, pomdp, state, a)
    s_prime = rand(d)
    reward = reward(pomdp, state, a)

    return (reward + (discount_factor) * rollout(s_prime, depth - 1))
end 

end # module

