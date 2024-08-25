using DataFrames
using Requires

mutable struct pile_stats 
    Age::Number
    average_height::AbstractFloat
    n_topples::Integer
    edge_loss::Integer

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



function topple!(sand_pile::SandPile, (i,j), cascade_stats)
    sand_pile.Grid[i,j] = sand_pile.topple_value
    sand_pile.stats.n_topples +=1

    ## top edge
    if i != 1
        sand_pile.Grid[i - 1, j] += sand_pile.spread_value
        cascade!(sand_pile, (i-1, j), cascade_stats)
    elseif i == 1
        cascade_stats[1].edge_loss += 1
    end

    ## bottom edge
    if  i != sand_pile.n
        sand_pile.Grid[i + 1, j] += sand_pile.spread_value
        cascade!(sand_pile, (i+1, j), cascade_stats)
    elseif i == sand_pile.n
        cascade_stats[1].edge_loss += 1
    end

    ## left edge
    if j != 1
        sand_pile.Grid[i, j-1] += sand_pile.spread_value
        cascade!(sand_pile, (i, j-1), cascade_stats)
    elseif j == 1
        cascade_stats[1].edge_loss += 1
    end

    ## right edge
    if  j != sand_pile.m
        sand_pile.Grid[i , j + 1] += sand_pile.spread_value
        cascade!(sand_pile, (i, j+1), cascade_stats)
    elseif j == sand_pile.m
        cascade_stats[1].edge_loss +=1
    end
end

function cascade!(sand_pile::SandPile, cell, cascade_stats)

    if sand_pile.Grid[CartesianIndex(cell)] == sand_pile.k
        topple!(sand_pile, cell, cascade_stats)
        cascade_stats[1].total_topples_at_t +=1
        if cell ∉ cascade_stats[2]
            push!(cascade_stats[2], cell)
            cascade_stats[1].unique_topples_at_t +=1
        end
    end
end

function average_pile_height(pile::SandPile)
    sum(pile.Grid)/pile.n^2   
end

function simulate_sandpile(size::Tuple{Int, Int} = (10,10); t_max::Int = prod(size)*4, drop_placement::String = "center", plot::String = "none")
    
    pile = SandPile(size[1], size[2], 4)
    stats_log = DataFrame(
        t = Int64[],
        total_topples_at_t = Int64[],
        unique_topples_at_t= Int64[],
        edge_loss= Int64[],
        average_height = Float64[],
        cum_topples = Int64[]
    )

    push!(stats_log, [0,0,0,0, 0.0, 0])

    if plot != "none"
        fps = 1000

        fig = Figure()
        hm_ax = Axis(fig[1,1],  yaxisposition = :left)
        stats_timeline = fig[1,2] = GridLayout(3,1)
        height_line_ax = Axis(stats_timeline[1,1], yaxisposition = :right, ylabel = "Average height", flip_ylabel = true)
        topple_line_ax = Axis(stats_timeline[2,1], yaxisposition = :right, ylabel = "Total Topples", flip_ylabel = true)
        topple_freq_ax = Axis(stats_timeline[3,1], yaxisposition = :right, ylabel = "Edge Loss", flip_ylabel = true, xscale = Makie.pseudolog10, yscale = Makie.pseudolog10)

        obs_grid = Observable(pile.Grid)
        Makie.heatmap!(hm_ax, obs_grid, colorrange = (0,4))
        hidedecorations!(hm_ax)

        Average_height_points = Observable([Point2f(pile.stats.Age, pile.stats.average_height)])
        lines!(height_line_ax, Average_height_points)
        hidexdecorations!(height_line_ax)

        n_topple_points = Observable([Point2f(pile.stats.Age, pile.stats.n_topples)])
        lines!(topple_line_ax, n_topple_points)
        hidexdecorations!(topple_line_ax)

        cascade_size_freq = Observable(stats_log[:, :total_topples_at_t])
        uniq_freq = Observable(stats_log[:, :unique_topples_at_t])
        hist!(topple_freq_ax, cascade_size_freq, bins = 100)
        #hist!(topple_freq_ax, uniq_freq, color = (:yellow, 0.5), bins = 10)

        GLMakie.display(fig)
        
        sleep(1/fps)
    end

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
        cascade!(pile, (x_d, y_d), (stats_log[i, :], unique_topples))

        # update pile object stats
        pile.stats.average_height = average_pile_height(pile)
        pile.stats.edge_loss += stats_log[i, :edge_loss]

        # update stats log
        #stats_log[i, :total_topples_at_t] = pile.stats.n_topples
        stats_log[i, :cum_topples] = pile.stats.n_topples
        stats_log[i, :average_height] = pile.stats.average_height

        # update plot
        if plot == "realtime"
            
            obs_grid[] = pile.Grid
            Average_height_points[] = push!(Average_height_points[], (pile.stats.Age, pile.stats.average_height))
            n_topple_points[] = push!(n_topple_points[], (pile.stats.Age, pile.stats.n_topples))
        
            if stats_log.total_topples_at_t[i] > 0
                uniq_freq[] = push!(uniq_freq[], stats_log.unique_topples_at_t[i])
                cascade_size_freq[] = push!(cascade_size_freq[], stats_log.total_topples_at_t[i])
            end

            autolimits!(height_line_ax)
            autolimits!(topple_line_ax)
            autolimits!(topple_freq_ax)
            sleep(1/fps)
        end
    end
    return stats_log
end
