## Check that the toppling/stabilization process is working correctly
include("../src/sand_src.jl")

## Test the topple! function
grid = [0 0 0; 0 4 0; 0 0 0]
pile = SandPile(grid)
@code_warntype push_topple!(pile, CartesianIndex(2,2))
@assert pile.grid == [0 1 0; 1 0 1; 0 1 0]

grid = [4 0 0; 0 0 0; 0 0 0]
pile = SandPile(grid)
push_topple!(pile, CartesianIndex(1,1))
@assert pile.grid == [0 1 0; 1 0 0; 0 0 0]

## Test the stabilise! function
### Naive push stabilise function
grid = [3 3 3; 3 4 3; 3 3 3]
pile = SandPile(grid)
stabilise!(pile, push_topple!)
@assert pile.grid == [1 3 1; 3 0 3; 1 3 1]

grid = fill(3,11,11)
site = CartesianIndex(6,6)
grid[site] = 4
pile = SandPile(grid)
stabilise!(pile, push_topple!, [site])
@assert all(pile.grid .< 4)

grid = fill(3,20,20)
site = CartesianIndex(7, 7)
grid[site] = 4
pile = SandPile(grid)
stabilise!(pile, push_topple!, [site])
@assert all(pile.grid .< 4)

### Naive pull stabilise function
grid = [3 3 3; 3 4 3; 3 3 3]
pile = SandPile(grid)
stabilise!(pile, pull_topple!)
@assert pile.grid == [1 3 1; 3 0 3; 1 3 1]

grid = fill(3,20,20)
site = CartesianIndex(7, 7)
grid[site] = 4
pile = SandPile(grid)
stabilise!(pile, pull_topple!)
@assert all(pile.grid .< 4)

### Naive multithreaded push stabilise function

grid = [3 3 3; 3 4 3; 3 3 3]
pile = SandPile(grid)
stabilise!(pile, pull_topple!, MultiThreaded())
@assert pile.grid == [1 3 1; 3 0 3; 1 3 1]

grid = fill(3,20,20)
site = CartesianIndex(7, 7)
grid[site] = 4
pile = SandPile(grid)
stabilise!(pile, pull_topple!, MultiThreaded())
@assert all(pile.grid .< 4)



## Simulate function
grid_size = 20
grid = rand(0:3, grid_size, grid_size)
rand_spot = CartesianIndex(rand(1:grid_size), rand(1:grid_size))
center = CartesianIndex((grid_size ÷ 2) +1 , (grid_size ÷ 2)+1) 
grid[center] = 4
pile = SandPile(grid)
findall(x->x==4, pile.grid)
print(pile.grid)
stabilise!(pile, push_topple!, [center])
@assert all(pile.grid .< 4)
##test the simulate_sandpile function
statlog = simulate_sandpile(13)

statlog.topples_at_t |> maximum