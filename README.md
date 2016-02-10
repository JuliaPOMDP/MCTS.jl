[![Build Status](https://travis-ci.org/sisl/MCTS.jl.svg?branch=master)](https://travis-ci.org/sisl/MCTS.jl)
[![Coverage Status](https://coveralls.io/repos/sisl/MCTS.jl/badge.svg)](https://coveralls.io/r/sisl/MCTS.jl)

# MCTS

This package implements the Monte-Carlo Tree Search algorithm in Julia for solving Markov decision processes (MDPs).
The user should define the problem according to the API in [POMDPs.jl](https://github.com/sisl/POMDPs.jl). Examples of
problem definitions can be found in [POMDPModels.jl](https://github.com/sisl/POMDPModels.jl). For an extensive tutorial, see [this](http://nbviewer.ipython.org/github/sisl/POMDPs.jl/blob/master/examples/GridWorld.ipynb) notebook.

Special thanks to Jon Cox for writing the original version of this code.

## Installation

Start Julia and run the following command:

```julia
Pkg.clone("https://github.com/sisl/MCTS.jl")
```

## Usage

The following functions must be defined in order to use MCTS:

```julia
discount(mdp::POMDP) # returns the discount factor
n_actions(mdp::POMDP) # returns the nubmer of actions in the problem
actions(mdp::POMDP) # returns the action space
actions(mdp::POMDP, s::State, as::ActionSpace) # fills the action space as with the actions availiable from state s
transition(mdp::POMDP, s::State, a::Action, d::AbstractDistribution) # fills d with neighboring states reachable from the s,a pair
rand(rng::AbstractRNG, d::AbstractDistribution) # returns an action selected from the transition distribution
reward(mdp::POMDP, s::State, a::Action) # returns the immediate reward of being in state s and performing action a
isterminal(mdp::POMDP, s::State) # returns a boolean indicating if state s is terminal
create_state(mdp::POMDP) # initializes a model state
create_action(mdp::POMDP) # initializes a model action
create_transition_distribution(mdp::POMDP) # initializes a distirbution over states
# if you want to use a random policy you need to implement an action space sampling function
rand(rng::AbstractRNG, action_space::AbstractSpace) # selects a random action from action space

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
solver = MCTSSolver(rollout_solver=rollout_policy) # default solver parameters will be used n_iterations=100, depth=10, exploration_constant=1.0
# note that the rollout_solver optional argument can be a solver or a policy
policy = solve(solver, mdp)
```

Since Monte-Carlo Tree Search is an online method, the solve function simply specifies the mdp model to the solver (which is embedded in the policy object). (Note that an MCTSPolicy can also be constructed directly without calling `solve()`.) The computation is done during calls to the action function. To extract the policy for a given state, simply call the action function:

```julia
s = create_state(mdp) # this can be any valid state
a = action(polciy, s) # returns the action for state s
```
