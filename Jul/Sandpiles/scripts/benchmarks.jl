using Pkg; Pkg.activate("Jul/Sandpiles")

using BenchmarkTools
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
test_grids = create_test_grids(21)

results = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])

for (i, grid) in enumerate(test_grids)
    bench = @benchmark stabilise!(pile, pull_topple!) setup = (pile = SandPile(copy($grid)))
    push!(results, (size = i, time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
end

# Save results to CSV
CSV.write("Jul/Sandpiles/data/benchmarks/benchmark_pull_naive.csv", results)