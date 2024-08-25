##Exploratory analysis of different size sandpiles
using DataFrames
using CSV
using Statistics
## Import data

pile_stats = [CSV.read("data/$(i)_sandpile.csv", DataFrame) for i in 10:10:100]

## get data after first edgeloss
t_at_first_loss = [first(pile_stats[i][pile_stats[i].edge_loss .> 0, :]).t for i in 1:10]

stabilising_pile = Vector{DataFrame}(undef, 10)
for i in 1:10
    stabilising_pile[i] = pile_stats[i][pile_stats[i].t .> t_at_first_loss[i], :]
    stabilising_pile[i].size .= i*10
    stabilising_pile[i][!, :cum_edge_loss] = cumsum(stabilising_pile[i].edge_loss)
end


## Plotting
using AlgebraOfGraphics
using GLMakie
map(data, stabilising_pile) |>
    x -> foldl(+, x) |>
    x -> *(x, mapping(:t, :cum_edge_loss, color = :size)) |>
    x -> *(x, visual(Scatter)) |>
    draw()



map(x -> mean(x.average_height), stabilising_pile)

