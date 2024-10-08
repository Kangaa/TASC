# frequency of different topple sizes

using CSV
using DataFrames
using GLMakie, Colors
using Statistics
using GLM
using StatsBase
using AlgebraOfGraphics

files = readdir("data")


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
        df = CSV.read(joinpath("data", file), DataFrame)
        
        # Add columns for size and rep
        df[!, :size] = fill(size, nrow(df))
        df[!, :rep] = fill(rep, nrow(df))
        
        # Append to the all_data DataFrame
        append!(all_data, df)
    end
end



topple_freq_stats = all_data  |>
    x -> groupby(x, [:size]) |>
    x -> combine(x, :topples_at_t => (y -> countmap(y)) => :topple_freqs) |>
    x -> transform(x,
     :topple_freqs => ByRow(y -> DataFrame(topple_size = collect(keys(y)),
     frequency = collect(values(y)))) => :topple_freqs) |>
    x -> transform(x, :topple_freqs => ByRow(y -> DataFrame(
        topple_size = y.topple_size,
        frequency = y.frequency,
        log_topple_size = log.(y.topple_size),
        log_frequency = log.(y.frequency)
    )) => :topple_freqs)

fig = Figure()
ax = Axis(fig[1, 1], xlabel = "log(Topple Size)", ylabel = "log(Frequency)")

for size_stats in eachrow(topple_freq_stats)
    grid_size = size_stats.size
    topple_freqs = size_stats.topple_freqs
    scatter!(ax, topple_freqs.log_topple_size, topple_freqs.log_frequency, alpha = 0.6, label = "$(size_stats.size)")
end

fig

##Calculate OLS coefficients
ols = map(
        function (x)
            data = filter( x -> x.log_topple_size .!= -Inf, x.topple_freqs)
            lm = GLM.lm(@formula(log_frequency ~ log_topple_size), data)
            beta_hat = coef(lm)
            return DataFrame(
                size = x.size,
                intercept = beta_hat[1],
                slope = beta_hat[2]
            )
        end, 
        eachrow(topple_freq_stats)) |>
    x -> reduce(vcat, x)


ablines!(ax,  ols.intercept, ols.slope, linewidth = 1.5)


### Just the ratio between size 1 and 2
log_freq_of_sz_1 = topple_freq_stats.topple_freqs[9][topple_freq_stats.topple_freqs[9].topple_size .== 1, :].log_frequency[1]
log_freq_of_sz_2 = topple_freq_stats.topple_freqs[9][topple_freq_stats.topple_freqs[9].topple_size .== 2, :].log_frequency[1] 

(log_freq_of_sz_1 - log_freq_of_sz_2)/(log(1)- log(2))

abline!(ax,10, (log_freq_of_sz_1 - log_freq_of_sz_2)/(log(1)- log(2)), linewidth = 1.5, color = :red) 