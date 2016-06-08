using Documenter, MCTS

makedocs()

deploydocs(
    repo = "github.com/JuliaPOMDP/MCTS.jl.git"
    julia = "release",
    osname = "linux"
)
