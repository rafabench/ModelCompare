"""
    struct BoundsDiff

Carry the information needed to compare the variable bounds between two models.
"""
struct BoundsDiff
    equal  :: Vector{String}
    both   :: Dict{String, Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}}
    first  :: Dict{String, Tuple{Float64, Float64}}
    second :: Dict{String, Tuple{Float64, Float64}}
end

function compare_bounds(model1::MOI.ModelLike, model2::MOI.ModelLike, vardiff::VariablesDiff; tol::Float64)
    indices1 = index_for_name(model1)
    indices2 = index_for_name(model2)

    bounds_first = Dict(name => MOIU.get_bounds(model1, Float64, indices1[name])
                        for name in vardiff.only_one)
    bounds_snd   = Dict(name => MOIU.get_bounds(model2, Float64, indices2[name])
                        for name in vardiff.only_two)

    bounds_both = Dict{String, Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}}()
    equal = String[]
    for name in vardiff.in_both
        b1 = MOIU.get_bounds(model1, Float64, indices1[name])
        b2 = MOIU.get_bounds(model2, Float64, indices2[name])
        if all(isapprox.(b1, b2; atol = tol))
            push!(equal, name)
        else
            bounds_both[name] = (b1, b2)
        end
    end

    return BoundsDiff(sort!(equal), bounds_both, bounds_first, bounds_snd)
end

function compare_bounds(model1::MOI.ModelLike, model2::MOI.ModelLike; kws...)
    return compare_bounds(model1, model2, compare_variables(model1, model2); kws...)
end

function printdiff(io::IO, bdiff::BoundsDiff)
    both, only1, only2 = bdiff.both, bdiff.first, bdiff.second

    print_header(io, "VARIABLE BOUNDS")

    if true #compare_one_by_one
        ## For each variable, print the difference between models
        if !isempty(both)
            write(io, "\tSAME VARIABLES\n")
            for (name, (b1, b2)) in both
                write(io, "\t", name, "\n")
                write(io, "\t\t", "MODEL 1 => ", string(b1) ,"\n")
                write(io, "\t\t", "MODEL 2 => ", string(b2) ,"\n")
            end
        end

        if !isempty(only1) || !isempty(only2)
            write(io, "\tDIFFERENT VARIABLES:\n")
        end

        if !isempty(only1)
            write(io, "\t", "MODEL 1:", "\n")
            for (name, b) in only1
                write(io, "\t\t", name, " => ", string(b) ,"\n")
            end
        end

        if !isempty(only2)
            write(io, "\t", "MODEL 2:", "\n")
            for (name, b) in only2
                write(io, "\t\t", name, " => ", string(b) ,"\n")
            end
        end
    else
        ## Separate variables per model
        write(io, "\tMODEL 1:\n")
        for (name, (b, _)) in both
            write(io, "\t\t", name, " => ", string(b) ,"\n")
        end
        for (name, b) in only1
            write(io, "\t\t", name, " => ", string(b) ,"\n")
        end

        write(io, "\tMODEL 2:\n")
        for (name, (_, b)) in both
            write(io, "\t\t", name, " => ", string(b) ,"\n")
        end
        for (name, b) in only2
            write(io, "\t\t", name, " => ", string(b) ,"\n")
        end
    end
end
