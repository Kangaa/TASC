#benchmark analysis
using Pkg; Pkg.activate("Jul/Sandpiles")
using CSV
using DataFrames
using GLMakie

files = readdir("./Jul/Sandpiles/data/benchmarks")
data = DataFrame(method = String[], size = Int[], time = Float64[], memory = Float64[], allocations = Int[])
for file in files
    if startswith(file, "Benchmark")
        df = CSV.read(joinpath("./Jul/Sandpiles/data/benchmarks", file), DataFrame)
        file = splitext(file)[1]
        params = split(file, "_")
        benchmark_size_range = params[2]
        topple_method = params[3]
        stabilisation_method = params[4]
        df[!, :method] = fill(stabilisation_method*topple_method*benchmark_size_range, nrow(df))

        append!(data, df)
    end
end

unique_methods = unique(data.method)
color_map = Dict(method => RGBf(rand(), rand(), rand()) for method in unique_methods)

data[!, :color] = [color_map[method] for method in data.method]
grouped_data = groupby(data, :method)


fig = Figure()
ax_time = Axis(fig[1, 1], title = "Benchmark Analysis", xlabel = "Size", ylabel = "Time (ns)")
ax_alloc = Axis(fig[2, 1][1,1], title = "Benchmark Analysis", xlabel = "Size", ylabel = "Allocations")
ax_mem = Axis(fig[2, 1][1,2], title = "Benchmark Analysis", xlabel = "Size", ylabel = "Memory (bytes)")

for group in grouped_data
    method = group.method[1]
    scatterlines!(ax_time, group.size, group.time, color = color_map[method], label = method, markersize = 5)
    scatterlines!(ax_alloc, group.size, group.allocations, color = color_map[method], label = method, markersize = 5)
    scatterlines!(ax_mem, group.size, group.memory, color = color_map[method], label = method, markersize = 5)
end
axislegend(ax_time)
fig

save("Manuscript/Quarto/topple_algos_benchmark.png", fig)