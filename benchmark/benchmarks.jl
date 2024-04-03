using MCTS # `] dev . ` in this folder's environment to benchmark the local version of MCTS.jl
using POMDPs
using POMDPModels
using Random
using BenchmarkTools
using Random
using Dates, LibGit2

function generate_benchmark_name(; haslength = 8)
    r = LibGit2.GitRepo(".")
    h = LibGit2.head(r)
    branch = LibGit2.shortname(h)
    hash = string(LibGit2.GitHash(h))[1:haslength]

    datetime = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")

    joinpath(dirname(@__FILE__), "results", "benchres_$branch-$(hash)_$datetime")
end


SUITE = BenchmarkGroup()
SUITE["vanilla"] = BenchmarkGroup(["gridworld","vanilla"])
include("vanilla_gridworld.jl")

# Load or tune benchmarking parameters. You should only compare performance with the same parameters.
paramspath = joinpath(dirname(@__FILE__), "params.json")
if isfile(paramspath)
    loadparams!(SUITE, BenchmarkTools.load(paramspath)[1], :evals)
else
    tune!(SUITE)
    BenchmarkTools.save(paramspath, params(SUITE))
end

suite_results = run(SUITE; verbose=true)
BenchmarkTools.save("$(generate_benchmark_name()).json", suite_results)

# To profile performance issue, run following code:

# using Profile, ProfileView
# @profile run(SUITE; verbose=true)
# ProfileView.view()