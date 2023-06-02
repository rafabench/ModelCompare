struct VariablesDiff
    in_both  :: Vector{String}
    only_one :: Vector{String}
    only_two :: Vector{String}
end

function compare_variables(model1::MOI.ModelLike, model2::MOI.ModelLike)
    return  VariablesDiff(partition(variable_names(model1), variable_names(model2))...)
end


function printdiff(io::IO, vardiff::VariablesDiff)
    only1, only2 = vardiff.only_one, vardiff.only_two

    p = ProgressUnknown("Comparing variables...")

    if !isempty(only1) || !isempty(only2)
        print_header(io, "VARIABLE NAMES")
        next!(p)
    end

    if !isempty(only1)
        write(io, "\tOnly MODEL 1\n")
        for vname in only1
            write(io,"\t\t", vname,"\n")
            next!(p)
        end
    end

    if !isempty(only2)
        write(io, "\tOnly MODEL 2\n")
        for vname in only2
            write(io,"\t\t", vname,"\n")
            next!(p)
        end
    end

    return vardiff
end

"""
    variables_names(model)

An iterator over all the variable names in a model.
"""
function variable_names(m::MOI.ModelLike)
    # TODO: Can we extract this without snooping into the model's private fields?
    # That is, only with MOI.get?
    return values(m.var_to_name)
end

function index_for_name(m::MOI.ModelLike)
    return Dict(v => k for (k, v) in m.var_to_name)
end
