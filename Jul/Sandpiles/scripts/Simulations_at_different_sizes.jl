## Run a series of sandpiles at different sizes and save the results to csv files
include("../src/Sandpiles.jl")
using CSV

sizes = [10, 20, 30, 40, 50]

for i in sizes
    statlog = Sandpiles.simulate_sandpile((i,i))
    CSV.write("./data/abelian_sandpile_$(i)x$(i).csv", statlog)
end

