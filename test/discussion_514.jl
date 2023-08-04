using CommonRLSpaces
using Distributions
using LinearAlgebra
using StaticArrays

struct D514MDP <: MDP{SVector{3,Float64}, SVector{2,Float64}} end

POMDPs.states(m::D514MDP) = Box([-5,-5,-3], [5,5,3])
POMDPs.actions(m::D514MDP) = Box([-5,-5], [5,5])
POMDPs.transition(m::D514MDP, s, a, dt=0.1) = MvNormal(s, Diagonal([0.1,0.1,0.1]))
POMDPs.reward(m::D514MDP, s, a, sp) = 0
POMDPs.discount(m::D514MDP) = 0.9

m = D514MDP()
solver = DPWSolver(max_time=1.0)
policy = solve(solver, m)
a = action(policy, [0.0,0.0,0.0])
@test a in actions(m)
