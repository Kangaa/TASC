
### from 'parralell_sandpile.jl'

function neighbours(sand_pile::SandPile, i::IndexLinear)
    i,j = IndexCartesian(i, sand_pile.Grid)
    neighbours = []
    for cell in ((i-1,j), (i+1,j), (i,j-1), (i,j+1))
            if cell[1] in 1:sand_pile.n && cell[2] in 1:sand_pile.m 
                push!(neighbours, sand_pile.Grid[CartesianIndex(cell)])
            end
        end
    return neighbours
end

function neighbours(sand_pile::SandPile, (i,j))
    i,j =(i,j)
    neighbours = []
    for cell in ((i-1,j), (i+1,j), (i,j-1), (i,j+1))
            if cell[1] in 1:sand_pile.n && cell[2] in 1:sand_pile.m 
                push!(neighbours, sand_pile.Grid[CartesianIndex(cell)])
            end
        end
    return neighbours
end

function cell_change((i,j), sand_pile::SandPile)
    i,j = (i,j)
    change::Int = 0
    if sand_pile.Grid[i,j] >= 4
        change -= 4
    end 
    change += sum(neighbours(sand_pile, (i,j)) .> 3)
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

