## Problem pile
include("topple_src.jl")
bad_guy = SandPile(
    [2 3 2 3 2;
3 2 3 2 3;
2 3 3 3 2;
3 2 3 2 3;
2 3 2 3 2], 5,5,4)


topple!(bad_guy, (3,3))
