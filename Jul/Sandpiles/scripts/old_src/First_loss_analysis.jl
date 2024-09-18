##Exploratory analysis of different size sandpiles
using DataFrames
using CSV
## Import data

pile_stats = [CSV.read("data/$(i)_sandpile.csv", DataFrame) for i in 10:10:100]

## first occurence of edge loss
first_edge_loss = [DataFrame(first(pile_stats[i][pile_stats[i].edge_loss .> 0, :])) for i in 1:10]

for i in eachindex(first_edge_loss)
    first_edge_loss[i][!, :size] = [10*i]
end


 t_at_first_edge = vcat(first_edge_loss...)

 using GLMakie
 using AlgebraOfGraphics

     plot_t = data(t_at_first_edge) * mapping(:size, :t => log => "log") * visual(ScatterLines)
    draw(plot_t)

    plot_topples = data(t_at_first_edge) * mapping(:size, :cum_topples=> (x -> log(x)) => "log") * visual(ScatterLines)
 draw(plot_topples)

plot_height = data(t_at_first_edge) * mapping(:size => (x -> log(x)) => "log", :average_height) * visual(ScatterLines)
 draw(plot_height)



 fig = Figure()
    draw!(fig[1,1], plot_t)
    draw!(fig[2,1], plot_topples)
    draw!(fig[3,1], plot_height)

Axis(fig[1,1], xscale = log10)




