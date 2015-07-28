
type MCTSDPWSolver <: Solver
	n_interations::Int64			
	depth::Int64					
	discount_factor::Float64		
	exploration_constant::Float64	
    tree::Dict{State, StateNode}
end

