## Parallel sandpile
include("topple_src.jl")

using Folds

function neighbours(sand_pile::SandPile, i, j)
    neighbours = []
    for cell in ((i-1,j), (i+1,j), (i,j-1), (i,j+1))
            if cell[1] in 1:sand_pile.n && cell[2] in 1:sand_pile.m 
                push!(neighbours, sand_pile.Grid[CartesianIndex(cell)])
            end
        end
    return neighbours
end

function cell_change(coordinates::Tuple, sand_pile::SandPile)
    i, j = coordinates
    change::Int = 0
    if sand_pile.Grid[i,j] >= 4
        change -= 4
    end 
    change += sum(neighbours(sand_pile, i,j) .> 3)
    return change
end


function change_matrix(sand_pile::SandPile)
    change_matrix = [cell_change((i, j), sand_pile) for i in 1:sand_pile.n, j in 1:sand_pile.m]
    return change_matrix
end

function change_matrix_map(sand_pile::SandPile)
    Folds.map(coord -> cell_change(Tuple(coord), sand_pile), eachindex(IndexCartesian(), sand_pile.Grid)) 
end

function stabilise_cells!(sand_pile::SandPile, parallel = true)
    if parallel
        while maximum(sand_pile.Grid) >= 4
        sand_pile.Grid += change_matrix_map(sand_pile)
        end
    end

    if !parallel
        while maximum(sand_pile.Grid) >= 4
        sand_pile.Grid += change_matrix(sand_pile)
        end
    end

    sand_pile.Grid
end

test_pile_1 = SandPile(rand(2:4, 100, 100))
test_pile_2 = deepcopy(test_pile_1)

using BenchmarkTools

@benchmark change_matrix_map($test_pile_1)
@benchmark change_matrix($test_pile_2)


using Profile   
using PProf 
Profile.Allocs.@profile change_matrix(test_pile_1)
PProf.Allocs.pprof()


@profview change_matrix(test_pile_1)
@profview change_matrix_map(test_pile_2)
