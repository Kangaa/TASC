using DataFrames
mutable struct pile_stats 
    age::Int64
    mass::Int64
    pile_stats() = new(0,0)
end


mutable struct SandPile
    grid::Matrix{Int}
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
    pile.grid[spread_locations] .+= pile.spread_value

    return spread_locations
end

function stabilise!(pile, sites)
    sites = [sites]
    topple_sites = []
    while !isempty(sites)
        site = popfirst!(sites)

        if pile.grid[site] >= pile.k
            append!(sites, topple!(pile, site))
            append!(topple_sites, [site])
        end
    end

    return topple_sites

end


function simulate_sandpile(size::Int = 10; k = 4, t_max::Int = prod(size)*4, drop_placement::String = "center", plot::String = "none")
    
    pile = SandPile(size, size, k)
    # Define the column names and types

    # Preallocate an empty array to hold the log with the specified length
    stats_log = DataFrame(Matrix{Int64}(undef, t_max, 4), [:t, :topples_at_t, :unique_topples_at_t, :mass])
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
        stats_log[i, :topples_at_t] = length(topple_sites)
        stats_log[i, :unique_topples_at_t] = length(unique(topple_sites))
        stats_log[i, :mass] = pile.stats.mass
    end

    return stats_log
end
