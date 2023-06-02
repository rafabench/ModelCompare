struct ExpressionDiff
    equal  :: Vector{String}
    both   :: Dict{String, Tuple{Float64, Float64}}
    first  :: Dict{String, Float64}
    second :: Dict{String, Float64}
end

function compare_expressions(expr1::MOI.AbstractScalarFunction, expr2::MOI.AbstractScalarFunction, model1::MOI.ModelLike, model2::MOI.ModelLike; tol::Float64)
    coefs1 = Dict(model1.var_to_name[t.variable] => t.coefficient for t in expr1.terms)
    coefs2 = Dict(model2.var_to_name[t.variable] => t.coefficient for t in expr2.terms)
    vardiff = VariablesDiff(partition(collect(keys(coefs1)), collect(keys(coefs2)))...)
    
    coefs_first =  Dict(name => coefs1[name] for name in vardiff.only_one)
    coefs_second = Dict(name => coefs2[name] for name in vardiff.only_two)
    coefs_both = Dict{String, Tuple{Float64, Float64}}()
    equal = String[]
    for name in vardiff.in_both
        c1 = coefs1[name]
        c2 = coefs2[name]
        if all(isapprox.(c1, c2; atol = tol))
            push!(equal, name)
        else
            coefs_both[name] = (c1, c2)
        end
    end

    return ExpressionDiff(sort!(equal), coefs_both, coefs_first, coefs_second)
end

function printdiff(io::IO, ediff::ExpressionDiff, name::String; one_by_one::Bool)
    equal, both, only1, only2 = ediff.equal, ediff.both, ediff.first, ediff.second

    if name != "OBJECTIVE"
       write(io, "\tCONSTRAINT: $name\n")
    end

    if one_by_one
        if !isempty(both)
            write(io, "\t\tSAME VARIABLES {MODEL1, MODEL2}\n")
            for (name, (b1, b2)) in both
                write(io, "\t\t", name, " => {", string(b1), ",",string(b2), "}\n")
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