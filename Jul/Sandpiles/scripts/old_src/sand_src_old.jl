using DataFrames
mutable struct pile_stats 
    age::Int64
    mass::Int64
    pile_stats() = new(0,0)
    pile_stats(age::Int64, mass::Int64) = new(age, mass)
end


mutable struct SandPile
    grid::Matrix{Int8}
    const n::Int
    const m::Int
    const k::Int
    const topple_value::Int
    const spread_value::Int
    stats::pile_stats

    SandPile(n,m,k) = new(
        zeros(n,m),
        n,
        m,
        k,
        k%4,
        k ÷ 4,
        pile_stats()
    )
    SandPile(grid::Matrix, n, m, k) = new(
        grid,
        n,m,k, k%4,
        k ÷ 4,
        pile_stats()
    )
    SandPile(grid::Matrix) = new(
        grid,
        size(grid, 1),
        size(grid, 2),
        4, 
        0,
        1,
        pile_stats(
            0,
            sum(grid)
        )
    )
end

function topple!(pile::SandPile, site::CartesianIndex)
    ## Assign memory for the spill locations vector
    spread_locations::Vector{CartesianIndex{2}} = CartesianIndex{2}[]
    
    ## Topple the site
    pile.grid[site] -= 4
       
    # Construct the spill locations vector
    if site[1] != 1
        push!(spread_locations, site - CartesianIndex(1,0))
    end

    if site[1] != pile.n
        push!(spread_locations, site + CartesianIndex(1,0))
    end

    if site[2] != 1
        push!(spread_locations, site - CartesianIndex(0,1))
    end

    if site[2] != pile.m
        push!(spread_locations, site + CartesianIndex(0,1))
    end

    ## Spread the sand
    @inbounds pile.grid[spread_locations] .+= pile.spread_value

    return spread_locations
end

function stabilise!(pile, sites)
    sites_queue = collect(sites)
    topple_sites = Vector{CartesianIndex}()
    while !isempty(sites_queue)
        site = popfirst!(sites_queue)

        if @inbounds pile.grid[site] >= pile.k
            append!(sites_queue, topple!(pile, site))
            append!(topple_sites, [site])
        end
    end

    return topple_sites
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

        # Stabilise pile
        topple_sites = stabilise!(pile, drop_loc)

        # update pile object stats
        pile.stats.mass = sum(pile.grid)

        # update stats log
        if isempty(topple_sites)
            stats_log[i, :max_dist] = 0
        elseif length(topple_sites) == 1
            stats_log[i, :max_dist] = 1
        else
            stats_log[i, :max_dist] = maximum([Euclidean_distance(drop_loc, site) for site in unique(topple_sites)])
        end
        stats_log[i, :topples_at_t] = length(topple_sites)
        stats_log[i, :unique_topples_at_t] = length(unique(topple_sites))
        stats_log[i, :mass] = pile.stats.mass
    end
    return stats_log
end

simulate_sandpile(10, k = 4, t_max = 100, drop_placement = "center", plot = "none")