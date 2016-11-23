# Double Progressive Widening 

The double progressive widening DPW solver is useful for problems with large (e.g. continuous) state and action spaces. It gradually expands the tree's branching factor so that the algorithm explores deeply even with large spaces.

See the papers at [https://hal.archives-ouvertes.fr/file/index/docid/542673/filename/c0mcts.pdf](https://hal.archives-ouvertes.fr/file/index/docid/542673/filename/c0mcts.pdf) and [http://arxiv.org/abs/1405.5498](http://arxiv.org/abs/1405.5498) for a description.

The solver fields are used to specify solver parameters. All of them can be specified as keyword arguments to the solver constructor.

```@docs
MCTS.DPWSolver
```
