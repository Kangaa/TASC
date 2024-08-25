# frequency of different topple sizes

using CSV
using DataFrames
using GLMakie
## 20 x 20 grid
reps = [CSV.read("data/simulation_20x20_rep_$(i).csv", DataFrame) for i in 1:30]


##function to get frequency data
function get_freqs(rep)
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


topple_freqs = map(get_freqs, reps) |>
    dfs -> (foldl(
        (x,y) -> outerjoin(x,y,on=:topple_size, makeunique=true), dfs)) |>
    df -> stack(df, Not(:topple_size), value_name=:frequency, variable_name = :rep) |>
    df -> transform(df, :frequency => ByRow(x->coalesce(x, 0)) => :frequency)



scatter(log.(topple_freqs.topple_size), log.(topple_freqs.frequency), alpha = 0.5)

topple_freq_stats = topple_freqs |> df -> combine(groupby(df, :topple_size), :frequency => mean => :mean, :frequency => std => :std)

lines(log.(topple_freq_stats.topple_size), log.(topple_freq_stats.mean))