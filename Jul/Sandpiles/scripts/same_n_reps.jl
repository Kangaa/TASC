## Many simulations of the same model, but with random sand drops
include("../src/Sandpiles.jl")
using CSV
n_sims = 100


function simulate_n_sandpiles(n_sims, size::Tuple)
    x = size[1]
    y = size[2]
    for i in 1:n_sims
        log = Sandpiles.simulate_sandpile((x,y); drop_placement = "rand")
        CSV.write("./data/simulation_$(x)x$(y)_rep_$i.csv", log)
    end
end
function simulate_n_sandpiles(n_sims, size::Int)
    x = size
    y = size
    for i in 1:n_sims
        log = Sandpiles.simulate_sandpile((x,y); drop_placement = "rand")
        CSV.write("./data/simulation_$(x)x$(y)_rep_$i.csv", log)
    end
end

simulate_n_sandpiles(100, 50)
