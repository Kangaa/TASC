using Pkg; Pkg.activate("Jul/Sandpiles")

using ArgParse
using BenchmarkTools
using DataFrames
using CSV

include("../src/sand_src.jl")

function create_test_grids(size::Int)
    grids = []
    grid = zeros(Int8, size, size)
    center = div(size, 2) + 1
    square_sizes = 3:2:size
    half_square = square_sizes .÷ 2 

    start_ix = center .- half_square
    end_ix = center .+ half_square

    for i in 1:length(square_sizes)
        grid[start_ix[i]:end_ix[i], start_ix[i]:end_ix[i]] .= 3
        grid[center, center] = 4
        push!(grids, copy(grid))
    end

    grids
end

# Define command-line arguments
function parse_command_line()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--method"
        help = "Benchmarking method: Push Targeted, Pull Naive ST, Pull Naive MT"
        arg_type = String
        required = true

        "--grid_size"
        help = "Size of the test grid"
        arg_type = Int
        required = true
    end
    return parse_args(s)
end

# Parse arguments
args = parse_command_line()
method = args["method"]
grid_size = args["grid_size"]

# Define test grids and avalanche sizes
test_grids = create_test_grids(grid_size)
center = [CartesianIndex(div(grid_size, 2) + 1, div(grid_size, 2) + 1)]

# Get avalanche size for each test grid
avalanche_sizes = []
for grid in test_grids
    grid = copy(grid)
    pile = SandPile(grid)
    stabilise!(pile, push_topple!)
    push!(avalanche_sizes, sum(pile.stats.topple_count))
end

# Benchmarking based on the method
if method == "Push naive"
    Results_Push_Targeted = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
    for (i, grid) in enumerate(test_grids)
        bench = @benchmark stabilise!(pile, push_topple!) setup = (pile = SandPile(copy($grid)))
        push!(Results_Push_Targeted, (size = avalanche_sizes[i], time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
    end
    CSV.write("Jul/Sandpiles/Data/Benchmarks/Benchmark_$(grid_size)_Push_naive.csv", Results_Push_Targeted)

elseif method == "Push Targeted"
    Results_Push_Targeted = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
    for (i, grid) in enumerate(test_grids)
        bench = @benchmark stabilise!(pile, push_topple!, center) setup = (pile = SandPile(copy($grid)))
        push!(Results_Push_Targeted, (size = avalanche_sizes[i], time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
    end
    CSV.write("Jul/Sandpiles/Data/Benchmarks/Benchmark_$(grid_size)_Push_Targeted.csv", Results_Push_Targeted)

elseif method == "Pull Naive ST"
    Results_Pull_NaiveST = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
    for (i, grid) in enumerate(test_grids)
        bench = @benchmark stabilise!(pile, pull_topple!) setup = (pile = SandPile(copy($grid)))
        push!(Results_Pull_NaiveST, (size = avalanche_sizes[i], time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
    end
    CSV.write("Jul/Sandpiles/Data/Benchmarks/Benchmark_$(grid_size)_Pull_NaiveST.csv", Results_Pull_NaiveST)

elseif method == "Pull Naive MT"
    Results_Pull_NaiveMT = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
    num_threads = Threads.nthreads()
    for (i, grid) in enumerate(test_grids)
        bench = @benchmark stabilise!(pile, pull_topple!, MultiThreaded()) setup = (pile = SandPile(copy($grid)))
        push!(Results_Pull_NaiveMT, (size = avalanche_sizes[i], time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
    end
    CSV.write("Jul/Sandpiles/Data/Benchmarks/Benchmark_$(grid_size)_Pull_NaiveMT$(num_threads)T.csv", Results_Pull_NaiveMT)

else
    error("Unknown method: $method")
end
