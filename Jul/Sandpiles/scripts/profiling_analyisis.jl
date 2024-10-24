using Pkg; Pkg.activate("Jul/Sandpiles")
using Profile
using ProfileView

include("../src/sand_src.jl")

TestGrid = fill(3, 101, 101)
TestGrid[51, 51] = 4
pile = SandPile(TestGrid)
Profile.@profile stabilise!(pile, push_topple!, [CartesianIndex(51, 51)])
ProfileView.view()
