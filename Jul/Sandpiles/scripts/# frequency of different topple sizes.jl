# frequency of different topple sizes

using CSV
using DataFrames
using GLMakie, Colors
using Statistics
using AlgebraOfGraphics


reps = DataFrame([CSV.read("data/simulation_$(j)x$(j)_rep_$(i).csv", DataFrame) for i in 1:100, j in [5, 10, 20, 50]], :auto)
reps = rename(reps, [Symbol("5x5"), Symbol("10x10"), Symbol("20x20"), Symbol("50x50")])

##function to get frequency data
function get_topple_freqs(rep)
    Freqs = DataFrame(topple_size = Int[], frequency = Int[])
    for row in eachrow(rep)
        if row.total_topples_at_t ∈ Freqs.topple_size
            Freqs.frequency[Freqs.topple_size .== row.total_topples_at_t] .+= 1
        else
            push!(Freqs, [row.total_topples_at_t, 1])
        end
    end
    return Freqs
end

topple_freqs = [DataFrame(),DataFrame(),DataFrame(),DataFrame()]
for i in 1:size(reps, 2)
    topple_freqs[i] = map(get_topple_freqs, reps[!, i])|>
    dfs -> (foldl(
        (x,y) -> outerjoin(x,y,on=:topple_size, makeunique=true), dfs)) |>
    df -> stack(df, Not(:topple_size), value_name=:frequency, variable_name = :rep) |>
    df -> transform(df, :frequency => ByRow(x->coalesce(x, 0)) => :frequency)|>
    df -> insertcols(df, :size=>["5", "10", "20", "50"][i] )
end
scatter(log.(topple_freqs[1].topple_size), log.(topple_freqs[1].frequency), alpha = 0.5, colormap = :viridis)

topple_freq_stats = map(df -> combine(groupby(df, [:topple_size, :size]), :frequency => mean => :mean, :frequency => std => :std), topple_freqs)

fig = Figure()
ax = Axis(fig[1, 1], xlabel = "log(Topple Size)", ylabel = "log(Frequency)")

for size_stats in topple_freq_stats
    scatter!(ax, log.(size_stats.topple_size), log.(size_stats.mean), label = "$(size_stats.size)")
end

fig


### fitting line to each size grid topple frequencies
using GLM
using StatsPlots
log_topple_freq_stats = map(df -> delete!(transform(df, :topple_size => ByRow(log) => :log_topple_size, :mean => ByRow(log) => :log_mean_freq), 1), topple_freq_stats)

lms = map(df -> lm(@formula(log_mean_freq ~ log_topple_size), df), log_topple_freq_stats)
intercepts = [coef(c)[1] for c in lms]
slopes = [coef(c)[2] for c in lms]

ablines!(ax, intercepts, slopes)
fig