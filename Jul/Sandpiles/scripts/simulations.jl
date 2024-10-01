include("../src/Sandpiles.jl")
using CSV

sizes = [701, 801, 901, 1001]

#center drop placement
for i in sizes
    statlog = Sandpiles.simulate_sandpile(i, drop_placement = "center")
    CSV.write("Jul/Sandpiles/data/center_$(i).csv", statlog)
end

#random drop placement
#nrep = 100
#sizes = [11, 21, 31, 41, 51, 61, 71, 81, 91, 101]
#for i in sizes
#    for j in 1:nrep
#        statlog = Sandpiles.simulate_sandpile(i, drop_placement = "random")
#        CSV.write("./Jul/Sandpiles/data/random_$(i)_rep_$(j).csv", statlog)
#    end
#end