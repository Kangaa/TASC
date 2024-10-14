# frequency of different topple sizes
using Pkg; Pkg.activate("Jul/Sandpiles")
using CSV
using DataFrames
using GLMakie, Colors, ColorSchemes
using Statistics
using StatsBase

files = readdir("Jul/Sandpiles/data/sims")

# Create a dictionary to store DataFrames with filenames as keys
all_data = DataFrame()

for file in files
    if startswith(file, "random")
        # Extract the filename without the extension
        name = splitext(file)[1]
        
        # Extract parameters from the filename (assuming format "random_size_rep.csv")
        parts = split(name, "_")
        size = parse(Int, parts[2])
        rep = parse(Int, parts[4])
        
        # Read the CSV file into a DataFrame
        df = CSV.read(joinpath("Jul/Sandpiles/data/sims", file), DataFrame)

        # Add columns for size and rep
        df[!, :size] = fill(size, nrow(df))
        df[!, :rep] = fill(rep, nrow(df))
        
        # Append to the all_data DataFrame
        append!(all_data, df)
    end
end



topple_stats = all_data  |>
    x -> groupby(x, [:size]) |>
    x -> combine(x,
     :topples_at_t => (y -> countmap(y)) => :topple_freqs,
     :topples_at_t => (y -> proportionmap(y)) => :topple_props) |>
    x -> transform(x,
        :size => ByRow(log) => :log_size,
        :topple_freqs =>
            ByRow(y -> DataFrame(
                topple_size = collect(keys(y)),
                frequency = collect(values(y)))) => :topple_freqs,
        :topple_props =>
            ByRow(y -> DataFrame(
                topple_size = collect(keys(y)),
                proportion = collect(values(y)))) => :topple_props)

topple_freq_stats = topple_stats |>
    x -> transform(x,
         :topple_freqs => ByRow(df -> begin
            df.log_topple_size = log.(df.topple_size);
            df.log_frequency = log.(df.frequency);
            df end) => :topple_freqs,
        :topple_props => ByRow(df -> begin
            df.log_topple_size = log.(df.topple_size);
            df.log_proportion = log.(df.proportion);
            df end) => :topple_props)


fig = Figure()
ax = Axis(fig[1, 1], xlabel = "log(Topple Size)", ylabel = "log(Frequency)")
size_colourrange = (minimum(topple_freq_stats.log_size), maximum(topple_freq_stats.log_size))

# absolute frequency
for size_stats in eachrow(topple_freq_stats)
    topple_freqs = size_stats.topple_freqs
    scatter!(ax,
     topple_freqs.log_topple_size,
     topple_freqs.log_frequency,
     colorrange = size_colourrange,
     color = size_stats.log_size,
     transparency = true,
     label = "$(size_stats.size)")
end

axislegend(ax, position = :rt)

save("Manuscript/figures/topple_freqs.png", fig)

#proportion

for size_stats in eachrow(topple_freq_stats)
    topple_props = size_stats.topple_props
    scatter!(ax,
     topple_props.log_topple_size, 
     topple_props.log_proportion,
     colorrange = size_colourrange,
     color = size_stats.log_size,
     transparency = true,
     label = "$(size_stats.size)")
end
fig

##Calculate OLS coefficients for raw frequencies
topple_freq_stats = subset(topple_freq_stats, :size => x-> x .> 10)

ols_freq = map(
        x -> begin
            data = filter(x -> x.log_topple_size .!= -Inf, x.topple_freqs)
            X = hcat(ones(size(data, 1)), data.log_topple_size)
            y = data.log_frequency
            beta_hat = X\y
            return DataFrame(
                size = x.size,
                intercept = beta_hat[1],
                slope = beta_hat[2]
            )
        end, 
        eachrow(topple_freq_stats)) |>
    x -> reduce(vcat, x)

for row in eachrow(ols_freq)
    size = row.size
    intercept = row.intercept
    slope = row.slope
    abline!(ax, intercept, slope, linewidth = 1.5, color = size, colorrange = (minimum(topple_freq_stats.size), maximum(topple_freq_stats.size)))
end

save("Manuscript/figures/topple_freqs_with_ols.png", fig)

##Calculate OLS coefficients for proportions
ols_prop = map(
        x -> begin
            data = filter(x -> x.log_topple_size .!= -Inf, x.topple_props)
            X = hcat(ones(size(data, 1)), data.log_topple_size)
            y = data.log_proportion
            beta_hat = (X'X)^-1 * X'y
            return DataFrame(
                size = x.size,
                intercept = beta_hat[1],
                slope = beta_hat[2]
            )
        end, 
        eachrow(topple_freq_stats)) |>
    x -> reduce(vcat, x)


for row in eachrow(ols_prop)
    size = row.size
    intercept = row.intercept
    slope = row.slope
    abline!(ax, intercept, slope, linewidth = 1.5, color = log(size), colorrange = size_colourrange)
end




## plot slope coefficients
fig = Figure()
ax = Axis(fig[1, 1], xlabel = "Size", ylabel = "Slope")
scatterlines!(ax, ols_freq.size, ols_freq.slope)

save("Manuscript/figures/slope_vs_size.png", fig)
### Just the ratio between size 1 and 2
log_freq_of_sz_1 = topple_freq_stats.topple_freqs[9][topple_freq_stats.topple_freqs[9].topple_size .== 1, :].log_frequency[1]
log_freq_of_sz_2 = topple_freq_stats.topple_freqs[9][topple_freq_stats.topple_freqs[9].topple_size .== 2, :].log_frequency[1] 

(log_freq_of_sz_1 - log_freq_of_sz_2)/(log(1)- log(2))

abline!(ax,10, (log_freq_of_sz_1 - log_freq_of_sz_2)/(log(1)- log(2)), linewidth = 1.5, color = :red) 