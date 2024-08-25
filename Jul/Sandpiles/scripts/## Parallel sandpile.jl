## Parallel sandpile
include("topple_src.jl")

# write function that gets a view of the subarray representing a cell's neighbours and stores them as an iterator
function neighbours(sand_pile::SandPile, i, j)
    neighbours = []
    for cell in [(i-1,j), (i+1,j), (i,j-1), (i,j+1)]
            if cell[1] in 1:sand_pile.n && cell[2] in 1:sand_pile.m 
                push!(neighbours, sand_pile.Grid[cell[1], cell[2]])
            end
        end
    return neighbours
end

function update_cell(coordinates, sand_pile::SandPile)
    i, j = coordinates
    if sand_pile.Grid[i,j] >= 4
        sand_pile.Grid[i,j] -= 4
    end
    sand_pile.Grid[i,j] += sum(neighbours(sand_pile, i,j) .> 3)
end

function update_cells(sand_pile::SandPile)
    for i in 1:sand_pile.n
        for j in 1:sand_pile.m
            update_cell((i,j), sand_pile)
        end
    end 
end


pile = SandPile(rand(0:4, 5,5))

update_cells(pile)