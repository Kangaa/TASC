using DataFrames
using CSV 
using StaticArrays
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

abstract type StabilisationMethod end
struct SingleThreaded <: StabilisationMethod end
struct MultiThreaded <: StabilisationMethod end

function get_neighbours(pile, site)
    neighbours = MVector{4, CartesianIndex{2}}(undef)
    n_neighbors = 0
    if site[1] != 1
        neighbours[n_neighbors += 1] = site - CartesianIndex(1,0)
    end
    if site[1] != pile.n
        neighbours[n_neighbors += 1] = site + CartesianIndex(1,0)
    end
    if site[2] != 1
        neighbours[n_neighbors += 1] = site - CartesianIndex(0,1)
    end
    if site[2] != pile.m
        neighbours[n_neighbors += 1] = site + CartesianIndex(0,1)
    end

    return @views neighbours[1:n_neighbors]
end

function get_neighbours(grid::Matrix, site::CartesianIndex)
    neighbours_2 = Vector{CartesianIndex{2}}(undef, 4)
    n_neighbors = 0
    if site[1] != 1
        @inbounds neighbours_2[n_neighbors += 1] = site - CartesianIndex(1, 0)
    end
    if site[1] != size(grid, 1)
        @inbounds neighbours_2[n_neighbors += 1] =  site + CartesianIndex(1,0)
    end
    if site[2] != 1
        @inbounds neighbours_2[n_neighbors += 1] = site - CartesianIndex(0,1)
    end
    if site[2] != size(grid, 2)
        @inbounds neighbours_2[n_neighbors += 1] = site + CartesianIndex(0,1)
    end

    return @views neighbours_2[1:n_neighbors]
end

function push_topple!(pile::SandPile, site::CartesianIndex)
    pile.grid[site] -= pile.k
    pile.stats.topple_count[site] += 1

    ## Spread the sand to neighbours
    spread_locations = get_neighbours(pile, site)
    @inbounds @views pile.grid[spread_locations] .+= 1
    return spread_locations
end

 function pull_topple!(Grid, pile, site)
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
    while any(pile.grid .>= pile.k)
        for site in eachindex(IndexCartesian(), pile.grid)
            if pile.grid[site] >= pile.k
                push_topple!(pile, site)
            end
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
        if pile.grid[site] >= pile.k
            spread = push_topple!(pile, site)
            for spread_site in spread
                push!(queue, spread_site)
            end
        end
    end
end

## naive pull stabilise function
function stabilise!(pile, ::typeof(pull_topple!))
    grid_copy = Array{Int8}(undef, size(pile.grid))
    while sum(pile.grid .>= pile.k) != 0
        grid_copy .= pile.grid
        for site in eachindex(IndexCartesian(), pile.grid)
            new_value, topple = pull_topple!(grid_copy, pile,  site)
            pile.grid[site] += new_value
        end
    end
end

# multithreaded naive pull stabilise function
function stabilise!(pile, ::typeof(pull_topple!), ::MultiThreaded)
    while sum(pile.grid .>= pile.k) != 0
        grid_copy = deepcopy(pile.grid)
        Threads.@threads for site in eachindex(IndexCartesian(), pile.grid)
            new_value, topple = pull_topple!(grid_copy, pile,  site)
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

function Manhattan_distance(p1::CartesianIndex, p2::CartesianIndex)
    return abs(p1[1] - p2[1]) + abs(p1[2] - p2[2])
end


function simulate_sandpile(
    size::Int = 10;
    k = 4,
    t_max::Int =(size^2)*4,
    drop_placement = "center",
    toppling_algorithm = push_topple!,
    plot::String = "none")
    
    pile = SandPile(size, size, k)

    pile.grid = rand(0:3, size, size)

    stats_log = DataFrame(
        t = 1:t_max,
        topples_at_t = zeros(Int, t_max),
        unique_topples_at_t = zeros(Int, t_max),
        mass = zeros(Int, t_max),
        max_dist_euc = zeros(Float64, t_max),
        max_dist_man = zeros(Float64, t_max)
    )


    for i in 1:t_max
        
        pile.stats.age += 1

        #drop random grain
        if drop_placement == "random"
            drop_loc = CartesianIndex(rand(1:size), rand(1:size))
        elseif drop_placement == "center"
            drop_loc = CartesianIndex((size ÷ 2) +1 , (size ÷ 2)+1) 
        else
            error("Invalid drop_placement option")
        end 

        pile.grid[drop_loc] += 1


        topples_at_last_t = copy(pile.stats.topple_count)

        # Stabilise pile
        stabilise!(pile, toppling_algorithm, [drop_loc])

        # update pile stats
        pile.stats.mass = sum(pile.grid)
 
        # update stats log
        topples_at_t = pile.stats.topple_count .- topples_at_last_t
        n_topples = sum(topples_at_t)
        unique_topples = findall(x -> x > 0, topples_at_t)

        if n_topples == 0
            stats_log[i, :max_dist_euc] = stats_log[i, :max_dist_man] = 0
        elseif n_topples == 1
            stats_log[i, :max_dist_euc] = stats_log[i, :max_dist_man] = 1
        else
            stats_log[i, :max_dist_euc] = maximum([Euclidean_distance(drop_loc, site) for site in unique_topples])
            stats_log[i, :max_dist_man] = maximum([Manhattan_distance(drop_loc, site) for site in unique_topples])
        end
        stats_log[i, :topples_at_t] = n_topples
        stats_log[i, :unique_topples_at_t] = length(unique_topples)
        stats_log[i, :mass] = pile.stats.mass
        # Check if the pile is stable
        @assert maximum(pile.grid) < k "$(pile.grid)"
    end
    return stats_log
end