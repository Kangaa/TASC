## Many simulations of the same model, but with random sand drops
include("../src/Sandpiles.jl")
using CSV
n_sims = 30

for i in 1:n_sims
    log = Sandpiles.simulate_sandpile((20,20); drop_placement = "rand")
    CSV.write("./data/simulation_20x20_rep_$i.csv", log)
end


