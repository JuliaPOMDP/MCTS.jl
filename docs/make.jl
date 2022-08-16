using Documenter, MCTS

makedocs()

deploydocs(
    deps = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/JuliaPOMDP/MCTS.jl.git",
    versions = ["stable" => "v^", "v#.#"],
)
