
function p(Lattice::AbstractArray{Int, d}, Site::NTuple{d, Integer}) where d 
    Lattice[CartesianIndex(Site)]
end

function p(Lattice::AbstractArray{Int, d}, Site::CartesianIndex) where d 
    Lattice[Site]
end

function is_stable(Lattice, k = 4)::Bool
    if [p(Lattice, i) >= k for i in eachindex(IndexCartesian(), Lattice)] |> iszero
        true
    else
        false
    end
end

function TopplingMatrix(Lattice, site)
    toppling_matrix = zeros(Int, size(Lattice))
    toppling_matrix[CartesianIndex(site)] = -2*length(size(Lattice))

    n = size(Lattice)[1]
    m = size(Lattice)[2]
       
    if site[1] != 1
        toppling_matrix[CartesianIndex(site) - CartesianIndex(1,0)] = 1 
    end

    if site[1] != n
        toppling_matrix[CartesianIndex(site) + CartesianIndex(1,0)] = 1
    end

    if site[2] != 1
        toppling_matrix[CartesianIndex(site) - CartesianIndex(0,1)] = 1
    end

    if site[2] != m
        toppling_matrix[CartesianIndex(site) + CartesianIndex(0,1)] = 1
    end

    toppling_matrix
end

function topple!(Lattice, Site)
    Lattice += TopplingMatrix(Lattice, Site)
end


function Update_Stabilisation_operator(Lattice, Stabilisation_operator,  k = 4)
    for (i,j) in pairs(Lattice .>= k)
        if j == 1
            push!(Stabilisation_operator, TopplingMatrix(Lattice, i))
        end
    end
end

function stabilise!(Lattice, stabilisation_operator = [zero(Lattice)])
    Final_lattice = Lattice
    while is_stable(Final_lattice) == false
            Update_Stabilisation_operator(Final_lattice, stabilisation_operator)
            Final_lattice = Lattice + sum(stabilisation_operator)
    end
    stabilisation_operator
end

lat = rand(0:4, 5,5)
op = stabilise!(lat)
is_stable(sum(op) + lat)
sum(op) + lat

# find topple sites
# add topple operators to list
# for each topple operator, apply to lattice

