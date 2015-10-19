# MCTS

This package implements the Monte-Carlo Tree Search algorithm in Julia for solving Markov decision processes (MDPs).
The user should define the problem according to the API in [POMDPs.jl](https://github.com/sisl/POMDPs.jl). Examples of
problem definitions can be found in [POMDPModels.jl](https://github.com/sisl/POMDPModels.jl). For an extensive tutorial, see [this](http://nbviewer.ipython.org/github/sisl/POMDPs.jl/blob/master/examples/GridWorld.ipynb) notebook.

## Installation

Start Julia and run the following command:

```julia
Pkg.clone("https://github.com/sisl/MCTS.jl")
```

## Usage

The following functions must be defined in order to use DiscreteValueIteration:

```julia
discount(mdp::POMDP) # returns the discount factor
states(mdp::POMDP) # returns the state space 
actions(mdp::POMDP) # returns the action space
actions(mdp::POMDP, s::State, as::ActionSpace) # fills the action space as with the actions availiable from state s
transition(mdp::POMDP, s::State, a::Action, d::AbstractDistribution) # fills d with neighboring states reachable from the s,a pair
rand!(rng::AbstractRNG, s::State, d::AbstractDistribution) # fills s with random sample from distribution d
reward(mdp::POMDP, s::State, a::Action) # returns the immediate reward of being in state s and performing action a

create_transition_distribution(mdp::POMDP) # initializes a distirbution over states
```

Once the above functions are defined, the solver can be called with the following syntax:

```julia
using MyMDP # module containing your MDP type and the associated functions
using MCTS

mdp = MyMDP() # initializes the MDP
solver = MCTSSolver(n_iterations=50, depth=20, exploration_constant=5.0) # initializes the Solver type
policy = MCTSPolicy(solver, mdp) # initializes the policy type
```

Since Monte-Carlo Tree Search is an online method, you do not need to call the solve function (although it is there for convenience). The computation is done during calls to the action function. To extract the policy for a given state, simply call the action function:

```julia
s = create_state(mdp) # this can be any valid state
a = action(mdp, polciy, s) # returns the action for state s
```
