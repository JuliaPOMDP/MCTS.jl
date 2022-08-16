using Documenter, MCTS

makedocs(
    modules = [MCTS],
    format = Documenter.HTML(),
    sitename = "MCTS.jl",
    pages = [
        "index.md",
        "vanilla.md",
        "dpw.md",
        "belief_mcts.md",
    ]
)

deploydocs(
    repo = "github.com/JuliaPOMDP/MCTS.jl.git",
    versions = ["stable" => "v^", "v#.#"],
)
