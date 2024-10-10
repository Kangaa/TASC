using DataFrames
using CSV
using StatsBase
using GLMakie

#import data
files = readdir("data")


# Create a dictionary to store DataFrames with filenames as keys
data = DataFrame()

for file in files
    if startswith(file, "center")
        # Extract the filename without the extension
        name = splitext(file)[1]
        
        # Extract parameters from the filename (assuming format "random_size_rep.csv")
        parts = split(name, "_")
        size = parse(Int, parts[2])
        
        # Read the CSV file into a DataFrame
        df = CSV.read(joinpath("data", file), DataFrame)
        
        # Add columns for size and rep
        df[!, :size] = fill(size, nrow(df))
        
        # Append to the all_data DataFrame
        append!(data, df)
    end
end


topple_stats = data  |>
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

# absolute frequency
for size_stats in eachrow(topple_freq_stats)
    topple_freqs = size_stats.topple_freqs
    scatter!(ax,
     topple_freqs.log_topple_size,
     topple_freqs.log_frequency,
     colorrange = (minimum(topple_freq_stats.log_size), maximum(topple_freq_stats.log_size)),
     color = size_stats.log_size,
     transparency = true,
     label = "$(size_stats.size)")
end

#proportion

for size_stats in eachrow(topple_freq_stats)
    grid_size = size_stats.size
    topple_props = size_stats.topple_props
    scatter!(ax,
     topple_props.log_topple_size, 
     topple_props.log_proportion,
     colorrange = (minimum(topple_freq_stats.size), maximum(topple_freq_stats.size)),
     color = size_stats.size,
     transparency = true,
     label = "$(size_stats.size)")
end
fig

##Calculate OLS coefficients for raw frequencies
ols_freq = map(
        x -> begin
            data = filter(x -> x.log_topple_size .!= -Inf, x.topple_freqs)
            X = hcat(ones(size(data, 1)), data.log_topple_size)
            y = data.log_frequency
            beta_hat = (X'X)^-1 * X'y
            return DataFrame(
                size = x.size,
                intercept = beta_hat[1],
                slope = beta_hat[2]
            )
        end, 
        eachrow(topple_freq_stats)) |>
    x -> reduce(vcat, x)

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

for row in eachrow(ols)
    size = row.size
    intercept = row.intercept
    slope = row.slope
    abline!(ax, intercept, slope, linewidth = 1.5, color = size, colorrange = (minimum(topple_freq_stats.log_size), maximum(topple_freq_stats.log_size)))
end


## plot slope coefficients
fig = Figure()
ax = Axis(fig[1, 1], xlabel = "Size", ylabel = "Slope")
scatter!(ax, ols.size, ols.slope, color = ols.size, colorrange = (minimum(topple_freq_stats.size), maximum(topple_freq_stats.size)))
