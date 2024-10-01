using BenchmarkTools

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

results = Vector(undef, length(test_grids))

for grid in enumerate(test_grids)
    i, grid = grid
   results[i] =  @benchmark stabilise!(pile, CartesianIndex(11,11)) setup = (pile = SandPile(copy($grid)))
end
results[5 ]