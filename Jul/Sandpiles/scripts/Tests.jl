## Check that the toppling/stabilization process is working correctly
include("../src/sand_src.jl")

## Test the topple! function
grid = [0 0 0; 0 4 0; 0 0 0]
pile = SandPile(grid)
push_topple!(pile, CartesianIndex(2,2))
@assert pile.grid == [0 1 0; 1 0 1; 0 1 0]

grid = [4 0 0; 0 0 0; 0 0 0]
pile = SandPile(grid)
push_topple!(pile, CartesianIndex(1,1))
@assert pile.grid == [0 1 0; 1 0 0; 0 0 0]

## Test the stabilise! function
grid = [3 3 3; 3 4 3; 3 3 3]
pile = SandPile(grid)
stabilise!(pile, push_topple!)
@assert pile.grid == [1 3 1; 3 0 3; 1 3 1]


grid = [3 3 3; 3 4 3; 3 3 3]
pile = SandPile(grid)
stabilise!(pile, pull_topple!, [CartesianIndex(2,2)])
@assert pile.grid == [1 3 1; 3 0 3; 1 3 1]


grid = [0 3 0; 3 4 3; 0 3 0]
pile = SandPile(grid)
stabilise!(pile, pull_topple!)
@assert pile.grid == [2 1 2; 1 0 1; 2 1 2]