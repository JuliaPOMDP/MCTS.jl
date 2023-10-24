var documenterSearchIndex = {"docs":
[{"location":"belief_mcts/#Belief-MCTS","page":"Belief MCTS","title":"Belief MCTS","text":"","category":"section"},{"location":"belief_mcts/","page":"Belief MCTS","title":"Belief MCTS","text":"The Belief MCTS solver allows MCTS to be used to solve POMDPs by transforming the POMDP to an MDP on the belief space.","category":"page"},{"location":"belief_mcts/","page":"Belief MCTS","title":"Belief MCTS","text":"MCTS.BeliefMCTSSolver","category":"page"},{"location":"belief_mcts/#MCTS.BeliefMCTSSolver","page":"Belief MCTS","title":"MCTS.BeliefMCTSSolver","text":"BeliefMCTSSolver(mcts_solver, updater)\n\nThe belief mcts solver solves POMDPs by modeling them as an MDP on the belief space. The updater is used to update the belief as part of the belief MDP generative model.\n\nExample:\n\nusing ParticleFilters\nusing POMDPModels\nusing MCTS\n\npomdp = BabyPOMDP()\nupdater = SIRParticleFilter(pomdp, 1000)\n\nsolver = BeliefMCTSSolver(DPWSolver(), updater)\nplanner = solve(solver, pomdp)\n\nsimulate(HistoryRecorder(max_steps=10), pomdp, planner, updater)\n\n\n\n\n\n","category":"type"},{"location":"dpw/#Double-Progressive-Widening","page":"Double Progressive Widening","title":"Double Progressive Widening","text":"","category":"section"},{"location":"dpw/","page":"Double Progressive Widening","title":"Double Progressive Widening","text":"The double progressive widening DPW solver is useful for problems with large (e.g. continuous) state and action spaces. It gradually expands the tree's branching factor so that the algorithm explores deeply even with large spaces.","category":"page"},{"location":"dpw/","page":"Double Progressive Widening","title":"Double Progressive Widening","text":"See the papers at https://hal.archives-ouvertes.fr/file/index/docid/542673/filename/c0mcts.pdf and http://arxiv.org/abs/1405.5498 for a description.","category":"page"},{"location":"dpw/","page":"Double Progressive Widening","title":"Double Progressive Widening","text":"The solver fields are used to specify solver parameters. All of them can be specified as keyword arguments to the solver constructor.","category":"page"},{"location":"dpw/","page":"Double Progressive Widening","title":"Double Progressive Widening","text":"MCTS.DPWSolver","category":"page"},{"location":"dpw/#MCTS.DPWSolver","page":"Double Progressive Widening","title":"MCTS.DPWSolver","text":"MCTS solver with DPW\n\nFields:\n\ndepth::Int64\n    Maximum rollout horizon and tree depth.\n    default: 10\n\nexploration_constant::Float64\n    Specified how much the solver should explore.\n    In the UCB equation, Q + c*sqrt(log(t/N)), c is the exploration constant.\n    default: 1.0\n\nn_iterations::Int64\n    Number of iterations during each action() call.\n    default: 100\n\nmax_time::Float64\n    Maximum amount of CPU time spent iterating through simulations.\n    default: Inf\n\nk_action::Float64\nalpha_action::Float64\nk_state::Float64\nalpha_state::Float64\n    These constants control the double progressive widening. A new state\n    or action will be added if the number of children is less than or equal to kN^alpha.\n    defaults: k:10, alpha:0.5\n\nkeep_tree::Bool\n    If true, store the tree in the planner for reuse at the next timestep (and every time it is used in the future). There is a computational cost for maintaining the state dictionary necessary for this.\n    default: false\n\nenable_action_pw::Bool\n    If true, enable progressive widening on the action space; if false just use the whole action space.\n    default: true\n\nenable_state_pw::Bool\n    If true, enable progressive widening on the state space; if false just use the single next state (for deterministic problems).\n    default: true\n\ncheck_repeat_state::Bool\ncheck_repeat_action::Bool\n    When constructing the tree, check whether a state or action has been seen before (there is a computational cost to maintaining the dictionaries necessary for this)\n    default: true\n\ntree_in_info::Bool\n    If true, return the tree in the info dict when action_info is called. False by default because it can use a lot of memory if histories are being saved.\n    default: false\n\nrng::AbstractRNG\n    Random number generator\n\nestimate_value::Any (rollout policy)\n    Function, object, or number used to estimate the value at the leaf nodes.\n    If this is a function `f`, `f(mdp, s, depth)` will be called to estimate the value (depth can be ignored).\n    If this is an object `o`, `estimate_value(o, mdp, s, depth)` will be called.\n    If this is a number, the value will be set to that number.\n    default: RolloutEstimator(RandomSolver(rng))\n\ninit_Q::Any\n    Function, object, or number used to set the initial Q(s,a) value at a new node.\n    If this is a function `f`, `f(mdp, s, a)` will be called to set the value.\n    If this is an object `o`, `init_Q(o, mdp, s, a)` will be called.\n    If this is a number, Q will always be set to that number.\n    default: 0.0\n\ninit_N::Any\n    Function, object, or number used to set the initial N(s,a) value at a new node.\n    If this is a function `f`, `f(mdp, s, a)` will be called to set the value.\n    If this is an object `o`, `init_N(o, mdp, s, a)` will be called.\n    If this is a number, N will always be set to that number.\n    default: 0\n\nnext_action::Any\n    Function or object used to choose the next action to be considered for progressive widening.\n    The next action is determined based on the MDP, the state, `s`, and the current `DPWStateNode`, `snode`.\n    If this is a function `f`, `f(mdp, s, snode)` will be called to set the value.\n    If this is an object `o`, `next_action(o, mdp, s, snode)` will be called.\n    default: RandomActionGenerator(rng)\n\ndefault_action::Any\n    Function, action, or Policy used to determine the action if POMCP fails with exception `ex`.\n    If this is a Function `f`, `f(pomdp, belief, ex)` will be called.\n    If this is a Policy `p`, `action(p, belief)` will be called.\n    If it is an object `a`, `default_action(a, pomdp, belief, ex)` will be called, and if this method is not implemented, `a` will be returned directly.\n    default: `ExceptionRethrow()`\n\nreset_callback::Function\n    Function used to reset/reinitialize the MDP to a given state `s`.\n    Useful when the simulator state is not truly separate from the MDP state.\n    `f(mdp, s)` will be called.\n    default: `(mdp, s)->false` (optimized out)\n\nshow_progress::Bool\n    Show progress bar during simulation.\n    default: false\n\ntimer::Function:\n    Timekeeping method. Search iterations ended when `timer() - start_time ≥ max_time`.\n\n\n\n\n\n","category":"type"},{"location":"#MCTS","page":"MCTS","title":"MCTS","text":"","category":"section"},{"location":"","page":"MCTS","title":"MCTS","text":"This package implements the Monte-Carlo Tree Search algorithm in Julia for solving Markov decision processes (MDPs). The user should define the problem according to the API in POMDPs.jl. Examples of problem definitions can be found in POMDPModels.jl. For an extensive tutorial, see this notebook.","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"Special thanks to Jon Cox for writing the original version of this code.","category":"page"},{"location":"#Installation","page":"MCTS","title":"Installation","text":"","category":"section"},{"location":"","page":"MCTS","title":"MCTS","text":"After installing POMDPs.jl, start Julia and run the following command:","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"using POMDPs\nPOMDPs.add(\"MCTS\")","category":"page"},{"location":"#Usage","page":"MCTS","title":"Usage","text":"","category":"section"},{"location":"","page":"MCTS","title":"MCTS","text":"Problems should be defined using the POMDPs.jl generative interface.","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"To see the methods that you need to implement to use MCTS with your MDP (assume you're defining an MDP of type MyMDP with states represented by integers and 3 possible integer actions), run","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"using POMDPs\nusing MCTS\n\nstruct MyMDP <: MDP{Int,Int} end\nPOMDPs.actions(::MyMDP) = [1,2,3]\n\n@requirements_info MCTSSolver() MyMDP() 1","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"(the 1 is any valid state). This should output something like","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"INFO: POMDPs.jl requirements for action(::AbstractMCTSPlanner, ::Any) and dependencies. ([✔] = implemented correctly; [X] = missing)\n\nFor action(::AbstractMCTSPlanner, ::Any):\n  [No additional requirements]\nFor simulate(::AbstractMCTSPlanner, ::Any, ::Int64) (in action(::AbstractMCTSPlanner, ::Any)):\n  [✔] discount(::MyMDP)\n  [✔] isterminal(::MyMDP, ::Int64)\n  [X] gen(::MyMDP, ::Int64, ::Int64, ::MersenneTwister)\nFor insert_node!(::AbstractMCTSPlanner, ::Any) (in simulate(::AbstractMCTSPlanner, ::Any, ::Int64)):\n  [✔] actions(::MyMDP, ::Int64)\n  [✔] iterator(::Tuple)\nFor estimate_value(::SolvedRolloutEstimator, ::MDP, ::Any, ::Int64) (in simulate(::AbstractMCTSPlanner, ::Any, ::Int64)):\n  [No additional requirements]\nFor rollout(::SolvedRolloutEstimator, ::MDP, ::Any, ::Int64) (in estimate_value(::SolvedRolloutEstimator, ::MDP, ::Any, ::Int64)):\n  [No additional requirements]\nFor simulate(::RolloutSimulator, ::MDP, ::Policy, ::Any) (in rollout(::SolvedRolloutEstimator, ::MDP, ::Any, ::Int64)):\n  [✔] action(::RandomPolicy, ::Int64)","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"indicating that the generative interface still needs to be implemented for MyMDP to be used with MCTS. See the geneartive interface documentation for further details.","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"Note: MDPs that implement the POMDPs.jl explicit interface can also be used with MCTS since the implementation of the explicit interface automatically defines the functions in the generative interface.","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"Once the above functions are defined, the solver can be called with the following syntax:","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"using MCTS\n\nmdp = MyMDP() # initializes the MDP\nsolver = MCTSSolver(n_iterations=50, depth=20, exploration_constant=5.0) # initializes the Solver type\nplanner = solve(solver, mdp) # initializes the planner","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"By default, the solver will use a random policy for rollouts. If you want to pass in a custom rollout policy you can run:","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"rollout_policy = MyCustomPolicy() # of type Policy, and has method action(rollout_policy::MyCustomPolicy, s::State)\nsolver = MCTSSolver(estimate_value=RolloutEstimator(rollout_policy)) # default solver parameters will be used n_iterations=100, depth=10, exploration_constant=1.0 = solve(solver, mdp)","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"Since Monte-Carlo Tree Search is an online method, the solve function simply specifies the mdp model to the solver (which is embedded in the policy object). (Note that an MCTSPlanner can also be constructed directly without calling solve().) The computation is done during calls to the action function. To extract the policy for a given state, simply call the action function:","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"s = rand(states(mdp)) # this can be any valid state\na = action(planner, s) # returns the action for state s","category":"page"},{"location":"#Solver-Variants","page":"MCTS","title":"Solver Variants","text":"","category":"section"},{"location":"","page":"MCTS","title":"MCTS","text":"There are currently two variants of the MCTS solver along with a Belief MCTS solver that can be used with POMDPs. They are documented in detail in the following sections:","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"Pages = [\n    \"vanilla.md\",\n    \"dpw.md\",\n    \"belief_mcts.md\"\n]\nDepth = 2","category":"page"},{"location":"#Visualization","page":"MCTS","title":"Visualization","text":"","category":"section"},{"location":"","page":"MCTS","title":"MCTS","text":"An example of visualization of the search tree in a jupyter notebook is here (or here is the version on github that will not display quite right but will still show you how it's done).","category":"page"},{"location":"","page":"MCTS","title":"MCTS","text":"To display the tree in a Google Chrome window, run using D3Trees; inchrome(D3Tree(policy, state)).","category":"page"},{"location":"#Incorporating-Additional-Prior-Knowledge","page":"MCTS","title":"Incorporating Additional Prior Knowledge","text":"","category":"section"},{"location":"","page":"MCTS","title":"MCTS","text":"An example of incorporating additional prior domain knowledge (to initialize Q and N) and to get an estimate of the value is here.","category":"page"},{"location":"vanilla/#Vanilla","page":"Vanilla","title":"Vanilla","text":"","category":"section"},{"location":"vanilla/","page":"Vanilla","title":"Vanilla","text":"The \"vanilla\" solver is the most basic version of MCTS. It works well with small discrete state and action spaces.","category":"page"},{"location":"vanilla/","page":"Vanilla","title":"Vanilla","text":"The solver fields are used to specify solver parameters. All of them can be specified as keyword arguments to the solver constructor.","category":"page"},{"location":"vanilla/","page":"Vanilla","title":"Vanilla","text":"MCTS.MCTSSolver","category":"page"},{"location":"vanilla/#MCTS.MCTSSolver","page":"Vanilla","title":"MCTS.MCTSSolver","text":"MCTS solver type\n\nFields:\n\nn_iterations::Int64\n    Number of iterations during each action() call.\n    default: 100\n\nmax_time::Float64\n    Maximum amount of CPU time spent iterating through simulations.\n    default: Inf\n\ndepth::Int64:\n    Maximum rollout horizon and tree depth.\n    default: 10\n\nexploration_constant::Float64:\n    Specifies how much the solver should explore.\n    In the UCB equation, Q + c*sqrt(log(t/N)), c is the exploration constant.\n    default: 1.0\n\nrng::AbstractRNG:\n    Random number generator\n\nestimate_value::Any (rollout policy)\n    Function, object, or number used to estimate the value at the leaf nodes.\n    If this is a function `f`, `f(mdp, s, remaining_depth)` will be called to estimate the value (remaining_depth can be ignored).\n    If this is an object `o`, `estimate_value(o, mdp, s, remaining_depth)` will be called.\n    If this is a number, the value will be set to that number\n    default: RolloutEstimator(RandomSolver(rng); max_depth=50, eps=nothing)\n\ninit_Q::Any\n    Function, object, or number used to set the initial Q(s,a) value at a new node.\n    If this is a function `f`, `f(mdp, s, a)` will be called to set the value.\n    If this is an object `o`, `init_Q(o, mdp, s, a)` will be called.\n    If this is a number, Q will be set to that number\n    default: 0.0\n\ninit_N::Any\n    Function, object, or number used to set the initial N(s,a) value at a new node.\n    If this is a function `f`, `f(mdp, s, a)` will be called to set the value.\n    If this is an object `o`, `init_N(o, mdp, s, a)` will be called.\n    If this is a number, N will be set to that number\n    default: 0\n\nreuse_tree::Bool:\n    If this is true, the tree information is re-used for calculating the next plan.\n    Of course, clear_tree! can always be called to override this.\n    default: false\n\nenable_tree_vis::Bool:\n    If this is true, extra information needed for tree visualization will\n    be recorded. If it is false, the tree cannot be visualized.\n    default: false\n\ntimer::Function:\n    Timekeeping method. Search iterations ended when `timer() - start_time ≥ max_time`.\n\n\n\n\n\n","category":"type"}]
}
