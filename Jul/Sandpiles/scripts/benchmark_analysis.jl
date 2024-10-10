#benchmark analysis
using Pkg; Pkg.activate("Jul/Sandpiles")
using CSV
using DataFrames
using GLMakie

files = readdir("./Jul/Sandpiles/data/benchmarks")
data = DataFrame(method = String[], size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
for file in files
    if startswith(file, "benchmark")
        df = CSV.read(joinpath("./Jul/Sandpiles/data/benchmarks", file), DataFrame)
        file = splitext(file)[1]
        topple_method = split(file, "_")[2]
        stabilisation_method = split(file, "_")[3]
        df[!, :method] = fill(stabilisation_method*topple_method, nrow(df))
        append!(data, df)
    end
end


# Generate a color palette
unique_methods = unique(data.method)
color_map = Dict(method => RGBf(rand(), rand(), rand()) for method in unique_methods)

# Assign colors to each data point
data[!, :color] = [color_map[method] for method in data.method]


# Group the data by method
grouped_data = groupby(data, :method)

# Plot each group

fig = Figure()
ax = Axis(fig[1, 1], title = "Benchmark Analysis", xlabel = "Size", ylabel = "Time (ns)")


for group in grouped_data
    method = group.method[1]
    scatterlines!(ax, group.size, group.time, color = color_map[method], label = method, markersize = 5)
end

# Add legend
axislegend(ax, position = :rt)
# Display the figure
fig

# Save the plot
save("Manuscript/Quarto/topple_algos_benchmark.png", fig)