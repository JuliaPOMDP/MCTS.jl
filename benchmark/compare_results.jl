using BenchmarkTools

RES_DIR = "./benchmark/results"
# OLD_RESULTS = "benchres_benchmarking-b9859ef4_2024-04-03_15-18-25.json"
BASELINE_RESULTS = "benchres_benchmarking-8e44d82c_2024-04-03_15-03-48.json"

# Load latest result
NEW_RESULTS =  sort(readdir(RES_DIR), by=x->last(x,24))[end]
PREVIOUS_RESULTS = sort(readdir(RES_DIR), by=x->last(x,24))[end-1]

baseline_results = BenchmarkTools.load(joinpath(RES_DIR, BASELINE_RESULTS))[1]
previous_results = BenchmarkTools.load(joinpath(RES_DIR, PREVIOUS_RESULTS))[1]
new_results = BenchmarkTools.load(joinpath(RES_DIR, NEW_RESULTS))[1]

println("Comparing latest results to baseline: \n\t$NEW_RESULTS\n\tto\n\t$BASELINE_RESULTS:")
@show BenchmarkTools.judge(median(baseline_results), median(new_results))

println("\nComparing latest results to previous: \n\t$NEW_RESULTS\n\tto\n\t$PREVIOUS_RESULTS:")
BenchmarkTools.judge(median(previous_results), median(new_results))