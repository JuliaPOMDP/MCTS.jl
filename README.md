# MCTS

[![CI](https://github.com/JuliaPOMDP/MCTS.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaPOMDP/MCTS.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/JuliaPOMDP/MCTS.jl/branch/master/graph/badge.svg?token=lwo3VqC7eQ)](https://codecov.io/gh/JuliaPOMDP/MCTS.jl)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliapomdp.github.io/MCTS.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliapomdp.github.io/MCTS.jl/dev)

[![MCTS Tree for Grid World, visualized](https://github.com/JuliaPOMDP/MCTS.jl/raw/master/img/tree.png)](https://nbviewer.jupyter.org/github/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Test_Visualization.ipynb)

This package implements the Monte-Carlo Tree Search algorithm in Julia for solving Markov decision processes (MDPs).
The user should define the problem as a [POMDPs.jl MDP model](https://juliapomdp.github.io/POMDPs.jl/stable/def_pomdp/). A simple example of the mountaincar problem defined with the `QuickPOMPDs` package can be found [here](https://github.com/JuliaPOMDP/QuickPOMDPs.jl/blob/master/examples/mountaincar.jl); additional examples of problem definitions can be found in [POMDPModels.jl](https://github.com/JuliaPOMDP/POMDPModels.jl). 

There is also a BeliefMCTSSolver that solves a POMDP by converting it to an MDP in the belief space.

Special thanks to Jon Cox for writing the original version of this code.

For reference, see the UCT algorithm in this paper:
Kocsis, Levente, and Csaba Szepesvári. "Bandit Based Monte-Carlo planning." European Conference on Machine Learning. Springer, Berlin, Heidelberg, 2006.

## Installation

In Julia, type, `]add MCTS`

## Documentation

Documentation can be found on the following site: [juliapomdp.github.io/MCTS.jl/latest/](http://juliapomdp.github.io/MCTS.jl/latest/)

## Usage

If `mdp` is an MDP defined with the [POMDPs.jl](https://github.com/sisl/POMDPs.jl) interface, the MCTS solver can be used to find an optimized action, `a`, for the MDP in state `s` as follows:

```julia
using POMDPs
using POMDPModels # for the SimpleGridWorld problem
using MCTS
using StaticArrays
mdp = SimpleGridWorld()
solver = MCTSSolver(n_iterations=50, depth=20, exploration_constant=5.0)
planner = solve(solver, mdp)
a = action(planner, SA[1,2])
```

See [this notebook](https://nbviewer.jupyter.org/github/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Test_Visualization.ipynb) for an example of how to visualize the search tree.

See [this notebook](https://github.com/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Domain_Knowledge_Example.ipynb) for examples of customizing solver behavior, specifically [the Rollouts section](https://github.com/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Domain_Knowledge_Example.ipynb#Rollouts) for using heuristic rollout policies.
