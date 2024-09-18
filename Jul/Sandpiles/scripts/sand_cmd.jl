include("../src/sand_src.jl")

using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "Gridsize"
            help = "a positional argument"
            required = true
            arg_type = Int
        "--reps"
            help = "number of simulations"
            arg_type = Int
            default = 1

    end

    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    println("Parsed args:")

    for i in 1:get(parsed_args, "reps", 1)
        simulate_sandpile(parsed_args["Gridsize"])
    end
end

main()