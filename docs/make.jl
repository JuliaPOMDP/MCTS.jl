using Documenter, MCTS

makedocs()

deploydocs(
    deps = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/JuliaPOMDP/MCTS.jl.git",
    julia = "0.6",
    osname = "linux"
)
