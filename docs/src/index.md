# MCTS

This package implements the Monte-Carlo Tree Search algorithm in Julia for solving Markov decision processes (MDPs).
The user should define the problem according to the API in [POMDPs.jl](https://github.com/sisl/POMDPs.jl). Examples of
problem definitions can be found in [POMDPModels.jl](https://github.com/sisl/POMDPModels.jl). For an extensive tutorial, see [this](http://nbviewer.ipython.org/github/sisl/POMDPs.jl/blob/master/examples/GridWorld.ipynb) notebook.

Special thanks to Jon Cox for writing the original version of this code.

## Installation

After installing [POMDPs.jl](https://github.com/sisl/POMDPs.jl), start Julia and run the following command:

```julia
using POMDPs
POMDPs.add("MCTS")
```

## Usage

Problems should be defined using the [POMDPs.jl interface](https://github.com/JuliaPOMDP/POMDPs.jl). Use of the [GenerativeModels.jl](https://github.com/JuliaPOMDP/GenerativeModels.jl) package to define state transition and reward sampling. The following functions should be implemented for the problem:
```julia
generate_sr(mdp::MDP, s, a, rng::AbstractRNG)
discount(mdp::MDP)
actions(mdp::MDP)
actions(mdp::MDP, s::State, as::ActionSpace)
isterminal(mdp::MDP, s::State)
```

To use the default random rollout policy, an action space sampling function
```julia
rand(rng::AbstractRNG, action_space::AbstractSpace)
```
must also be implemented.

Problems that do *not* use [GenerativeModels.jl](https://github.com/JuliaPOMDP/GenerativeModels.jl) can be used with MCTS.jl, but must have the following three functions defined *instead of* `generate_sr`.
```julia
transition(mdp::MDP, s, a, d::AbstractDistribution)
rand(rng::AbstractRNG, d::AbstractDistribution)
reward(mdp::MDP, s, a)
```

Once the above functions are defined, the solver can be called with the following syntax:

```julia
using MyMDP # module containing your MDP type and the associated functions
using MCTS

mdp = MyMDP() # initializes the MDP
solver = MCTSSolver(n_iterations=50, depth=20, exploration_constant=5.0) # initializes the Solver type
policy = solve(solver, mdp) # initializes the policy
```
By default, the solver will use a random policy for rollouts. If you want to pass in a custom rollout policy you can run:

```julia
rollout_policy = MyCustomPolicy() # of type Policy, and has method action(rollout_policy::MyCustomPolicy, s::State)
solver = MCTSSolver(estimate_value=RolloutEstimator(rollout_policy)) # default solver parameters will be used n_iterations=100, depth=10, exploration_constant=1.0
policy = solve(solver, mdp)
```

Since Monte-Carlo Tree Search is an online method, the solve function simply specifies the mdp model to the solver (which is embedded in the policy object). (Note that an MCTSPolicy can also be constructed directly without calling `solve()`.) The computation is done during calls to the action function. To extract the policy for a given state, simply call the action function:

```julia
s = create_state(mdp) # this can be any valid state
a = action(polciy, s) # returns the action for state s
```

## Solver Variants

There are currently two variants of the MCTS solver. They are documented in detail in the following sections:

```@contents
Pages = [
    "vanilla.md",
    "dpw.md",
]
Depth = 2
```

## Visualization

An example of visualization of the search tree in a jupyter notebook is [here](https://nbviewer.jupyter.org/github/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Test_Visualization.ipynb) (or [here](https://github.com/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Test_Visualization.ipynb) is the version on github that will not display quite right but will still show you how it's done).

## Incorporating Additional Prior Knowledge

An example of incorporating additional prior domain knowledge (to initialize Q and N) and to get an estimate of the value is [here](https://github.com/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Domain_Knowledge_Example.ipynb).
