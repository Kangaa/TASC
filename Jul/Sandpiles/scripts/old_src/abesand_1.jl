using GLMakie
using DataFrames

include("topple_src.jl")

function abelian_sandpile(n = 11, k = 4, Drop_schedule::String = "center", t_max = n*n*k)
    pile = SandPile(n,n,k)

    cascade_stats_log = DataFrame(
        t = Int64[],
        total_topples = Int64[],
        unique_topples= Int64[],
        edge_loss= Int64[])

    for i in 1:t_max
            pile.stats.Age += 1

            push!(cascade_stats_log, [0,0,0,0])
            cascade_stats_log.t[i] = i


            #drop random grain
            if Drop_schedule == "rand"
                x_d = rand(1:n)
                y_d = rand(1:n)
            elseif Drop_schedule == "center"
                x_d = (n ÷ 2) + 1
                y_d = (n ÷ 2) + 1
            end

            pile.Grid[x_d, y_d] += 1
            unique_topples::Vector{Tuple{Int, Int}} = []
            cascade!(pile, (x_d, y_d), (cascade_stats_log[i, :], unique_topples))
            pile.stats.average_height = average_pile_height(pile)
            
    end
    return cascade_stats_log
end

log = abelian_sandpile(50, 4, "rand", 10000)

Fig = Figure()
ax_t = Axis(Fig[1,1])
lines!(ax_t, log.t, log.total_topples, color = :red)
lines!(ax_t, log.t, log.unique_topples, color = :blue)
lines!(ax_t, log.t, log.edge_loss, color = :green)
display(Fig)




non_zerostats = filter(:total_topples => !=(0), log)
Fig = Figure()
ax1 = Axis(Fig[1,1])
ax2 = Axis(Fig[2,1])
ax3 = Axis(Fig[3,1])
hist!(Fig[1,1], non_zerostats.total_topples)
hist!(Fig[2,1], non_zerostats.unique_topples)
hist!(Fig[3,1], non_zerostats.edge_loss)
display(Fig)


Fig = Figure()
ax = Axis(Fig[1,1])
hist!(ax, non_zerostats.edge_loss, color = :red)
display(Fig)