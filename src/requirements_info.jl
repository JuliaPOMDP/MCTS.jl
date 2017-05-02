function POMDPs.requirements_info(solver::AbstractMCTSSolver, problem::Union{POMDP,MDP})
    if state_type(typeof(problem)) <: Number
        s = one(state_type(typeof(problem)))
        requirements_info(solver, problem, s)
    else
        println("""
            Since MCTS is an online solver, most of the computation occurs in `action(policy, state)`. In order to view the requirements for this function, please, supply a state as the third argument to `requirements_info`, e.g.

                @requirements_info $(typeof(solver))() $(typeof(problem))() $(state_type(typeof(problem)))()

                """)
    end
end

function POMDPs.requirements_info(solver::AbstractMCTSSolver, problem::Union{POMDP,MDP}, s)
    policy = solve(solver, problem)
    requirements_info(policy, s)
end

function POMDPs.requirements_info(policy::AbstractMCTSPlanner, s)
    @show_requirements action(policy, s)    
end
