using GLMakie
Makie.inline!(false)

include("topple_src.jl")

function abelian_sandpile_1(n = 11, k = 4, Drop_schedule::String = "center", t_max = n*n*k)
    pile = SandPile(n,n,k)

    Average_height_stat = Observable([Point2f(0,0)])
    fps = 1000
    t = Observable(1)

    fig = Figure()
    hm_ax = Axis(fig[1,1], title = "sandpile" )
    line_ax = Axis(fig[1,2], title = "average height")

    obs_grid = Observable(pile.Grid)
    heatmap!(hm_ax, obs_grid, colorrange = (0,k))

    lines!(line_ax, Average_height_stat)

    display(fig)
    sleep(1/fps)

    for i in 1:t_max
            t[] += 1
            #drop random grain
            if Drop_schedule == "rand"
                x_d = rand(1:n)
                y_d = rand(1:n)
            elseif Drop_schedule == "center"
                x_d = (n ÷ 2) + 1
                y_d = (n ÷ 2) + 1
            end

            pile.Grid[x_d, y_d] +=1
        
            cascade(pile, (x_d, y_d))
            obs_grid[] = pile.Grid
            new_avg_pile_height = Point2f(t[], average_pile_height(pile))
            Average_height_stat[] = push!(Average_height_stat[], new_avg_pile_height)
            autolimits!(line_ax)
            sleep(1/fps)
    end
end

abelian_sandpile_1(10, 4, "rand", 10000)
