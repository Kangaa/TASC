#anim_demo
using GLMakie
using DataFrames
include("./src/topple_src.jl")


simulate_sandpile((20, 20), drop_placement = "rand", plot = "realtime")

