
mutable struct SandPile
    Grid::Matrix{Int}
    const n::Int
    const m::Int
    const k::Int
    const topple_value::Int
    const spread_value::Int

    SandPile(n,m,k) = new(
        zeros(n,m),
        n,
        m,
        k,
        k%4,
        k ÷ 4
    )
    SandPile(Grid::Matrix, n, m, k) = new(
        Grid,
        n,m,k, k%4,
        k ÷ 4
    )
end



function topple!(sand_pile::SandPile, (i,j))
    
    spread::Vector{Tuple{Int, Int}} = []

    sand_pile.Grid[i,j] = sand_pile.topple_value

    if i == 1
        sand_pile.Grid[i + 1, j] += sand_pile.spread_value
        cascade(sand_pile, (i+1, j))
    elseif  i == sand_pile.n
        sand_pile.Grid[i - 1, j] += sand_pile.spread_value
        cascade(sand_pile, (i-1, j))
    else
        sand_pile.Grid[i + 1, j] += sand_pile.spread_value
        cascade(sand_pile, (i+1, j))
        sand_pile.Grid[i - 1, j] += sand_pile.spread_value
        cascade(sand_pile, (i-1, j))
    end

    if j == 1
        sand_pile.Grid[i, j+1] += sand_pile.spread_value
        cascade(sand_pile, (i, j+1))
    elseif  j == sand_pile.n
        sand_pile.Grid[i , j- 1] += sand_pile.spread_value
        cascade(sand_pile, (i, j-1))
    else
        sand_pile.Grid[i, j + 1] += sand_pile.spread_value
        cascade(sand_pile, (i, j+1))
        sand_pile.Grid[i, j - 1] += sand_pile.spread_value
        cascade(sand_pile, (i, j-1))
    end
end

function cascade(sand_pile::SandPile, cell)
    i,j = cell
    if sand_pile.Grid[i,j] == sand_pile.k
        topple!(sand_pile, (i,j))
    end
end

function average_pile_height(pile::SandPile)
    sum(pile.Grid)/pile.n^2   
end