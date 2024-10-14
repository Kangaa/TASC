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
grid_size = 31
test_grids = create_test_grids(grid_size)
center = [CartesianIndex(div(grid_size, 2) + 1, div(grid_size, 2) + 1)]

# Get avalance size for each test grid
avalanche_sizes = []
for grid in test_grids
    grid = copy(grid)
    pile = SandPile(grid)
    stabilise!(pile, push_topple!)
    push!(avalanche_sizes, sum(pile.stats.topple_count))
end


## Push Topple
### Naive
Results_Push_Naive = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
for (i, grid) in enumerate(test_grids)
    bench = @benchmark stabilise!(pile, push_topple!) setup = (pile = SandPile(copy($grid)))
    push!(Results_Push_Naive, (size = avalanche_sizes[i], time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
end
CSV.write("Jul/Sandpiles/Data/Benchmarks/Benchmark_$(grid_size)_Push_Naive.csv", Results_Push_Naive)

### Targeted
Results_Push_Targeted = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
for (i, grid) in enumerate(test_grids)
    bench = @benchmark stabilise!(pile, push_topple!, center) setup = (pile = SandPile(copy($grid)))
    push!(Results_Push_Targeted, (size = avalanche_sizes[i], time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
end
CSV.write("Jul/Sandpiles/Data/Benchmarks/Benchmark_$(grid_size)_Pushstack_Targeted.csv", Results_Push_Targeted)

## Pull Topple
### Naive ST
Results_Pull_NaiveST = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
for (i, grid) in enumerate(test_grids)
    bench = @benchmark stabilise!(pile, pull_topple!) setup = (pile = SandPile(copy($grid)))
    push!(Results_Pull_NaiveST, (size = avalanche_sizes[i], time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
end
CSV.write("Jul/Sandpiles/Data/Benchmarks/Benchmark_$(grid_size)_Pull_NaiveST.csv", Results_Pull_NaiveST)
### Naive MT
Results_Pull_NaiveMT = DataFrame(size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
for (i, grid) in enumerate(test_grids)
    bench = @benchmark stabilise!(pile, pull_topple!, MultiThreaded()) setup = (pile = SandPile(copy($grid)))
    push!(Results_Pull_NaiveMT, (size = avalanche_sizes[i], time = minimum(bench).time, memory = minimum(bench).memory, allocations = minimum(bench).allocs))
end
CSV.write("Jul/Sandpiles/Data/Benchmarks/Benchmark_$(grid_size)_Pull_NaiveMT.csv", Results_Pull_NaiveMT)
