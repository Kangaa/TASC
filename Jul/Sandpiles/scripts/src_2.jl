using DataFrames
using SparseArrays
mutable struct pile_stats 
    Age::Number
    average_height::AbstractFloat
    n_topples::Integer
    etotal_dge_loss::Integer

    pile_stats() = new(0,0,0,0)
end


mutable struct SandPile
    Grid::Matrix{Int}
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
    SandPile(Grid::Matrix, n, m, k) = new(
        Grid,
        n,m,k, k%4,
        k ÷ 4,
        pile_stats()
    )
    SandPile(Grid::Matrix) = new(
        Grid,
        size(Grid, 1),
        size(Grid, 2),
        4, 
        0,
        1,
        pile_stats(
            0,
            sum(Grid)/prod(size(Grid)), 
            0,
            0
        )
    )
end

function is_stable(pile)::Bool
    if maximum(pile.Grid) < pile.k
        true
    else
        false
    end
end

function TopplingMatrix(pile, site)
    toppling_matrix = zeros(pile.n, pile.m)
    toppling_matrix[CartesianIndex(site)] = -4
       
    if site[1] != 1
        toppling_matrix[CartesianIndex(site) - CartesianIndex(1,0)] = 1 
    end

    if site[1] != pile.n
        toppling_matrix[CartesianIndex(site) + CartesianIndex(1,0)] = 1
    end

    if site[2] != 1
        toppling_matrix[CartesianIndex(site) - CartesianIndex(0,1)] = 1
    end

    if site[2] != pile.m
        toppling_matrix[CartesianIndex(site) + CartesianIndex(0,1)] = 1
    end

    toppling_matrix
end

function stabilise!(pile)
    stabilisation_operator = [zero(pile.Grid)]
    while is_stable(pile) == false
        for (i,j) in pairs(pile.Grid .>= pile.k)
            if j 
                pile.Grid += TopplingMatrix(pile, i)
            end
        end
    end
end

function simulate_sandpile(size::Tuple{Int, Int} = (10,10); t_max::Int = prod(size)*4, drop_placement::String = "center", plot::String = "none")
    
    pile = SandPile(size[1], size[2], 4)
    stats_log = DataFrame(
        t = Int64[],
        total_topples_at_t = Int64[],
        unique_topples_at_t= Int64[],
        total_edge_loss= Int64[],
        average_height = Float64[],
        cum_topples = Int64[]
    )

    push!(stats_log, [0,0,0,0, 0.0, 0])


    for i in 1:t_max
        pile.stats.Age += 1

        push!(stats_log, [0,0,0,0, 0.0, 0])
        stats_log.t[i] = i

        #drop random grain
        if drop_placement == "rand"
            x_d = rand(1:size[1])
            y_d = rand(1:size[2])
        elseif drop_placement == "center"
            x_d = (size[1] ÷ 2) + 1
            y_d = (size[2] ÷ 2) + 1
        end
        pile.Grid[x_d, y_d] += 1

        #initialise unique topple sites counter for this stabilisation
        unique_topples::Vector{Tuple{Int, Int}} = []

        # Stabilise pile
        while is_stable(pile) == false
            # initialise stabilisation operator
            stabilisation_operator = [zero(pile.Grid)]

            # stabilise pile
             stabilise!(pile)

            # update unique topples counter
            for (i,j) in pairs(pile.Grid .>= pile.k)
                if j == 1
                    push!(unique_topples, i)
                end
            end
        end

        # update pile object stats

        # update stats log
        #stats_log[i, :total_topples_at_t] = pile.stats.n_topples
        stats_log[i, :cum_topples] = pile.stats.n_topples
        stats_log[i, :average_height] = pile.stats.average_height

    end
    return stats_log
end


simulate_sandpile((10,10))