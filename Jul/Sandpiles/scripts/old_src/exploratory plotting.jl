# Analysis
using GLMakie
using DataFrames
using CSV
using AlgebraOfGraphics
using CategoricalArrays
## line plots of the 30 reps of the 20x20 grid
repsdata = DataFrame(
    t = Int64[],
    total_topples_at_t = Int16[],
    unique_topples_at_t = Int16[],
    edge_loss = Int64[],
    average_height = Float64[],
    cum_topples = Int64[],
    rep = String[])


for i in 1:30
    i_data = CSV.read("data/simulation_20x20_rep_$i.csv", DataFrame, skipto = 2, footerskip = 1)    
    insertcols!(i_data, 7, :rep => "$i")
    pop!(i_data)
    append!(repsdata, i_data)
end

height_rep_line_plot  = data(repsdata) * mapping(:t, :average_height, color = :rep) * visual(Lines) 
draw(height_rep_line_plot)

## alternative using AoG and multiple datalayers (one per rep)
reps_data_layers = [data(i) for i in [CSV.read("data/simulation_20x20_rep_$j.csv", DataFrame, footerskip = 1) for j in 1:30]]
reps_plot = foldl(+, reps_data_layers) * mapping(:t, :average_height) * visual(Lines,color = :red, alpha = 0.2)
draw(reps_plot)


## different lines for different grid sizes
size_data = DataFrame(
    t = [],
    total_topples_at_t = [],
    unique_topples_at_t = [],
    edge_loss = [],
    average_height = [],
    cum_topples =[],
    size = []
)

for i in 10:10:100
    i_data = CSV.read("data/$(i)_sandpile.csv", DataFrame)
    insertcols!(i_data, 7, :size => "i")
    pop!(i_data)
    append!(size_data, i_data)
end
tes_data = (; size_data.t, size_data.average_height, size_data.size))
size_line_plot = data(size_data) * mapping(:t, :average_height, color = :size => sorter([string.(10:10:50); string.(70:10:100); string(60)])) * visual(Lines)
draw(size_line_plot, scales(Color = (; palette = :hawaii10)))

fig = Figure()
ax = Axis(fig[1,1])
Makie.lines!(ax, repsdata.t, repsdata.average_height, color = repsdata.rep)

test = [data(i) for i in [CSV.read("data/$(j)_sandpile.csv", DataFrame, footerskip = 1) |>
 x -> insertcols!(x, 7, :size => "$j") for j in 10:10:100]]

layers = foldl(+, test)
plot = layers * mapping(:t, :average_height, color = :size) * visual(Lines)

draw(plot, scales(Color = (; palette = :hawaii10),
X = (; palette =2,)))  