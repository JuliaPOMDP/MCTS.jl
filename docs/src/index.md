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

Problems should be defined using the [POMDPs.jl generative interface](https://juliapomdp.github.io/POMDPs.jl/stable/def_pomdp/#Using-a-single-generative-function-instead-of-separate-T,-Z,-and-R).

To see the methods that you need to implement to use MCTS with your MDP (assume you're defining an MDP of type `MyMDP` with states represented by integers and 3 possible integer actions), run
```julia
using POMDPs
using MCTS

struct MyMDP <: MDP{Int,Int} end
POMDPs.actions(::MyMDP) = [1,2,3]

@requirements_info MCTSSolver() MyMDP() 1
```
(the `1` is any valid state). This should output something like
```
INFO: POMDPs.jl requirements for action(::AbstractMCTSPlanner, ::Any) and dependencies. ([✔] = implemented correctly; [X] = missing)

For action(::AbstractMCTSPlanner, ::Any):
  [No additional requirements]
For simulate(::AbstractMCTSPlanner, ::Any, ::Int64) (in action(::AbstractMCTSPlanner, ::Any)):
  [✔] discount(::MyMDP)
  [✔] isterminal(::MyMDP, ::Int64)
  [X] gen(::MyMDP, ::Int64, ::Int64, ::MersenneTwister)
For insert_node!(::AbstractMCTSPlanner, ::Any) (in simulate(::AbstractMCTSPlanner, ::Any, ::Int64)):
  [✔] actions(::MyMDP, ::Int64)
  [✔] iterator(::Tuple)
For estimate_value(::SolvedRolloutEstimator, ::MDP, ::Any, ::Int64) (in simulate(::AbstractMCTSPlanner, ::Any, ::Int64)):
  [No additional requirements]
For rollout(::SolvedRolloutEstimator, ::MDP, ::Any, ::Int64) (in estimate_value(::SolvedRolloutEstimator, ::MDP, ::Any, ::Int64)):
  [No additional requirements]
For simulate(::RolloutSimulator, ::MDP, ::Policy, ::Any) (in rollout(::SolvedRolloutEstimator, ::MDP, ::Any, ::Int64)):
  [✔] action(::RandomPolicy, ::Int64)
```
indicating that the generative interface still needs to be implemented for `MyMDP` to be used with MCTS. See the [geneartive interface documentation](https://juliapomdp.github.io/POMDPs.jl/stable/def_pomdp/#Using-a-single-generative-function-instead-of-separate-T,-Z,-and-R) for further details.

Note: MDPs that implement the [POMDPs.jl explicit interface](https://juliapomdp.github.io/POMDPs.jl/stable/def_pomdp/) can also be used with MCTS since the implementation of the explicit interface automatically defines the functions in the generative interface.

Once the above functions are defined, the solver can be called with the following syntax:

```julia
using MCTS

mdp = MyMDP() # initializes the MDP
solver = MCTSSolver(n_iterations=50, depth=20, exploration_constant=5.0) # initializes the Solver type
planner = solve(solver, mdp) # initializes the planner
```
By default, the solver will use a random policy for rollouts. If you want to pass in a custom rollout policy you can run:

```julia
rollout_policy = MyCustomPolicy() # of type Policy, and has method action(rollout_policy::MyCustomPolicy, s::State)
solver = MCTSSolver(estimate_value=RolloutEstimator(rollout_policy)) # default solver parameters will be used n_iterations=100, depth=10, exploration_constant=1.0 = solve(solver, mdp)
```

Since Monte-Carlo Tree Search is an online method, the solve function simply specifies the mdp model to the solver (which is embedded in the policy object). (Note that an MCTSPlanner can also be constructed directly without calling `solve()`.) The computation is done during calls to the action function. To extract the policy for a given state, simply call the action function:

```julia
s = rand(states(mdp)) # this can be any valid state
a = action(planner, s) # returns the action for state s
```

## Solver Variants

There are currently two variants of the MCTS solver along with a Belief MCTS solver that can be used with POMDPs. They are documented in detail in the following sections:

```@contents
Pages = [
    "vanilla.md",
    "dpw.md",
    "belief_mcts.md"
]
Depth = 2
```

## Visualization

An example of visualization of the search tree in a jupyter notebook is [here](https://nbviewer.jupyter.org/github/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Test_Visualization.ipynb) (or [here](https://github.com/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Test_Visualization.ipynb) is the version on github that will not display quite right but will still show you how it's done).

To display the tree in a Google Chrome window, run `using D3Trees; inchrome(D3Tree(policy, state))`.

## Incorporating Additional Prior Knowledge

An example of incorporating additional prior domain knowledge (to initialize Q and N) and to get an estimate of the value is [here](https://github.com/JuliaPOMDP/MCTS.jl/blob/master/notebooks/Domain_Knowledge_Example.ipynb).
