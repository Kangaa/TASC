include("../src/sand_src.jl")
using Pkg; Pkg.activate(".")
using ArgParse
using CSV

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "Gridsizes"
            help = "a positional argument"
            required = true
            arg_type = Int
            nargs = '+'

        "--distribution"
            help = "placement of sand drops"
            arg_type = String
            default = "random"

        "--reps"
            help = "number of simulations"
            arg_type = Int
            default = 1

    end

    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    gridsizes = parsed_args["Gridsizes"]
    distribution = get(parsed_args, "distribution", "random")
    reps = get(parsed_args, "reps", 1)

    println("Parsed args:")

    for gridsize in gridsizes
        for rep in 1:get(parsed_args, "reps", 1)
            sim_log = simulate_sandpile(gridsize; drop_placement=distribution)
            CSV.write("data/$(distribution)_$(gridsize)_rep_$(rep).csv", sim_log)
        end
    end
end

main()