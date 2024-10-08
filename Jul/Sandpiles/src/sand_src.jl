using DataFrames
using DataStructures
mutable struct pile_stats 
    age::Int64
    mass::Int64
    topple_count::Array{Int64}

    function pile_stats(grid)
        n, m = size(grid)
        new(0, sum(grid), zeros(Int64, n, m))
    end
end


mutable struct SandPile
    grid::Matrix{Int8}
    const n::Int
    const m::Int
    const k::Int
    const topple_value::Int
    const spread_value::Int
    stats::pile_stats

    function SandPile(n, m, k)
        grid = zeros(Int8, n, m)

        new(grid, n, m, k, k % 4, k ÷ 4, pile_stats(grid))
    end

    function SandPile(grid::Matrix) 
        n, m = size(grid)
        k = 2*length(size(grid))
    new(
        grid,
        n,
        m,
        k,
        k % 4,
        k ÷ 4, 
        pile_stats(grid)
    )
    end
end

function get_neighbours(pile, site)
    neighbours_2 = Vector{CartesianIndex{2}}(undef, 4)
    n_neighbors = 0
    if site[1] != 1
        neighbours_2[n_neighbors += 1] = site - CartesianIndex(1, 0)
    end
    if site[1] != pile.n
        neighbours_2[n_neighbors += 1] =  site + CartesianIndex(1,0)
    end
    if site[2] != 1
        neighbours_2[n_neighbors += 1] = site - CartesianIndex(0,1)
    end
    if site[2] != pile.m
        neighbours_2[n_neighbors += 1] = site + CartesianIndex(0,1)
    end

    return neighbours_2[1:n_neighbors]
end

function get_neighbours(grid::Matrix, site::CartesianIndex)
    neighbours_2 = Vector{CartesianIndex{2}}(undef, 4)
    n_neighbors = 0
    if site[1] != 1
        neighbours_2[n_neighbors += 1] = site - CartesianIndex(1, 0)
    end
    if site[1] != size(grid, 1)
        neighbours_2[n_neighbors += 1] =  site + CartesianIndex(1,0)
    end
    if site[2] != 1
        neighbours_2[n_neighbors += 1] = site - CartesianIndex(0,1)
    end
    if site[2] != size(grid, 2)
        neighbours_2[n_neighbors += 1] = site + CartesianIndex(0,1)
    end

    return neighbours_2[1:n_neighbors]
end

function push_topple!(pile::SandPile, site::CartesianIndex)
    if pile.grid[site] >= pile.k
        pile.grid[site] -= pile.k
        pile.stats.topple_count[site] += 1

        ## Spread the sand to neighbours
        spread_locations = get_neighbours(pile, site)
        pile.grid[spread_locations] .+= pile.spread_value
        return spread_locations
    else
        return CartesianIndex[]
    end
end

 function pull_topple!(Grid, site)
    new_value = 0
    topple = false
    neighbours = get_neighbours(Grid, site)
    for neighbour in neighbours
        if Grid[neighbour] >= pile.k
           new_value += pile.spread_value
        end
    end
    if Grid[site] >= pile.k
        new_value -= pile.k
        topple = true
    end
    return (new_value, topple)
end

## Naive push stabilise function
function stabilise!(pile, ::typeof(push_topple!))
    while sum(pile.grid .>= pile.k) != 0
        for site in eachindex(IndexCartesian(), pile.grid)
            push_topple!(pile, site)
        end
    end
end

## Targeted push stabilise function
function stabilise!(pile, ::typeof(push_topple!), sites)
    queue = Stack{CartesianIndex{2}}()
    for site in sites
        push!(queue, site)
    end

    while !isempty(queue)
        site = pop!(queue)
        spread = push_topple!(pile, site)
        for spread_site in spread
            if spread_site ∉ queue
                push!(queue, spread_site)
            end
        end
    end
end

## naive pull stabilise function
function stabilise!(pile, ::typeof(pull_topple!))
    while sum(pile.grid .>= pile.k) != 0
        grid_copy = deepcopy(pile.grid)
        for site in eachindex(IndexCartesian(), pile.grid)
            new_value, topple = pull_topple!(grid_copy, site)
            pile.grid[site] += new_value
        end
    end
end

## Targeted pull stabilise function
function stabilise!(pile, ::typeof(pull_topple!), sites)
    ## Queue setup
    queue = Deque{CartesianIndex{2}}()
    for site in sites
        push!(queue, site)
        neighbours = get_neighbours(pile, site)
        for neighbour in neighbours
            push!(queue, neighbour)
        end
    end
    while !isempty(queue)
        grid_copy = deepcopy(pile.grid)
        new_queue = []
        for i in 1:length(queue)
            site = popfirst!(queue)
            new_value, topple = pull_topple!(grid_copy, site)
            pile.grid[site] += new_value
            if topple
                for neighbour in get_neighbours(pile, site)
                    if neighbour ∉ queue
                        push!(new_queue, neighbour)
                    end
                end
            end
        end
        for site in new_queue
            push!(queue, site)
        end
    end
end


function Euclidean_distance(p1::CartesianIndex, p2::CartesianIndex)
    return sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)
end


function simulate_sandpile(size::Int = 10; k = 4, t_max::Int =(size^2)*4, drop_placement::String = "center", plot::String = "none")
    
    pile = SandPile(size, size, k)
    # Define the column names and types

    # Preallocate an empty array to hold the log with the specified length
    stats_log = DataFrame([Vector{T}(undef, t_max) for T in (Int, Int, Int, Int, Float64)] 
         , [:t, :topples_at_t, :unique_topples_at_t, :mass, :max_dist])
    stats_log[:, :t] = 1:t_max

    for i in 1:t_max
        pile.stats.age += 1

        #drop random grain
        if drop_placement == "random"
            drop_loc = CartesianIndex(rand(1:size), rand(1:size))
        elseif drop_placement == "center"
            drop_loc = CartesianIndex((size ÷ 2) +1 , (size ÷ 2)+1)
        end

        pile.grid[drop_loc] += 1
        pile.topple_check[drop_loc] = true

        # Stabilise pile
        stabilise!(pile)

        # update pile object stats
        pile.stats.mass = sum(pile.grid)

        # update stats log
        n_topples = sum(values(pile.topple_count))
        unique_topples = keys(filter(x-> x[2] > 0, pile.topple_count))
        if n_topples == 0
            stats_log[i, :max_dist] = 0
        elseif n_topples == 1
            stats_log[i, :max_dist] = 1
        else
            stats_log[i, :max_dist] = maximum([Euclidean_distance(drop_loc, site) for site in unique_topples])
        end
        stats_log[i, :topples_at_t] = n_topples
        stats_log[i, :unique_topples_at_t] = length(unique_topples)
        stats_log[i, :mass] = pile.stats.mass

        # Check if the pile is stable
        @assert maximum(pile.grid) < k


        # reset topple counter
        for site in keys(pile.topple_count)
            pile.topple_count[site] = 0
        end
    end
    return stats_log
end
