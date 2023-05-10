function compare_variables(model1::MOI.ModelLike, model2::MOI.ModelLike, openfile)
    p = ProgressUnknown("Comparing variables...")

    inboth, only1, only2 = partition(variable_names(model1), variable_names(model2))

    if !isempty(only1) || !isempty(only)
        print_header(openfile, "VARIABLE NAMES")
        next!(p)
    end

    if !isempty(only1)
        write(openfile, "\tMODEL 1\n")
        for vname in only1
            write(openfile,"\t\t", vname,"\n")
            next!(p)
        end
    end

    if !isempty(only2)
        write(openfile, "\tMODEL 2\n")
        for vname in only2
            write(openfile,"\t\t", vname,"\n")
            next!(p)
        end
    end
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
