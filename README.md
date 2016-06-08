# MCTS

[![Build Status](https://travis-ci.org/JuliaPOMDP/MCTS.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/MCTS.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaPOMDP/MCTS.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaPOMDP/MCTS.jl?branch=master)

This package implements the Monte-Carlo Tree Search algorithm in Julia for solving Markov decision processes (MDPs).
The user should define the problem according to the API in [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl). Examples of
problem definitions can be found in [POMDPModels.jl](https://github.com/JuliaPOMDP/POMDPModels.jl). For an extensive tutorial, see [this](http://nbviewer.ipython.org/JuliaPOMDP/sisl/POMDPs.jl/blob/master/examples/GridWorld.ipynb) notebook.

Special thanks to Jon Cox for writing the original version of this code.

## Installation

After installing [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl), start Julia and run the following command:

```julia
using POMDPs
POMDPs.add("MCTS")
```

## Documentation

Documentation can be found on the following site: juliapomdp.github.io/MCTS.jl/latest/

## Usage Example

If `mdp` is an MDP defined with the [POMDPs.jl](https://github.com/sisl/POMDPs.jl) interface, the MCTS solver can be used to find an optimized action, `a`, for the MDP in state `s` as follows:

```julia
using MCTS
solver = MCTSSolver(n_iterations=50, depth=20, exploration_constant=5.0)
policy = solve(solver, mdp)
a = action(policy, s)
```
