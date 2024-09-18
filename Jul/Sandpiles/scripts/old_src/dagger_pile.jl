## Parallelise using Dagger.jl tasks
include("topple_src.jl")
## first across threads
using Dagger

##for each cell in sandpile, add a task which will update the cell
function update(sand_pile::SandPile)
    change_matrix = zeros(Int8, sand_pile.n, sand_pile.m)
    for i in 1:sand_pile.n
        for j in 1:sand_pile.m
            Dagger.spawn((x,y, sand_pile) -> begin
                change[x,y] = cell_change((x,y), sand_pile)
        end,(i,j), sand_pile)
        end
    end
    change_matrix
end

test_pile_1 = SandPile(rand(2:4, 100, 100))

update(test_pile_1)


change_matrix = zeros(Int8, test_pile_1.n, test_pile_1.m)
    for i in 1:test_pile_1.n
        for j in 1:test_pile_1.m
            map(((x,y, sand_pile),) -> begin
                cchange = cell_change((x,y), sand_pile)
                change_matrix[x,y] = cchange
                print(change)
        end,(i,j, test_pile_1))
        end
    end
    change_matrix