function compare_bounds(model1, model2, lists, openfile, tol, compare_one_by_one)
    equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index = lists

    bounds_1 = Tuple{Float64, Float64}[]
    bounds_2 = Tuple{Float64, Float64}[]

    p = ProgressMeter.ProgressUnknown("Comparing variables bounds...")

    for i in MOI.get(model1, MOI.ListOfVariableIndices())
        push!(bounds_1, MOIU.get_bounds(model1, Float64, i))
        ProgressMeter.next!(p)
    end

    for i in MOI.get(model2, MOI.ListOfVariableIndices())
        push!(bounds_2, MOIU.get_bounds(model2, Float64, i))
        ProgressMeter.next!(p)
    end

    equal_bounds = Dict()
    same_var_1_uniq_bounds = Dict()
    same_var_2_uniq_bounds = Dict()
    for i = 1:length(equals_names_index_1)
        b1 = bounds_1[equals_names_index_1[i]]
        b2 = bounds_2[equals_names_index_2[i]]

        if all(isapprox.(b1, b2; atol = tol))
            equal_bounds[equals_names[i]] = b1
        else
            same_var_1_uniq_bounds[equals_names[i]] = b1
            same_var_2_uniq_bounds[equals_names[i]] = b2
        end

        ProgressMeter.next!(p)
    end

    diff1_bounds = Dict()
    diff2_bounds = Dict()
    for i = 1:length(diffs1_index)
        diff1_bounds[diffs1[i]] = bounds_1[diffs1_index[i]]
        ProgressMeter.next!(p)
    end

    for i = 1:length(diffs2_index)
        diff2_bounds[diffs2[i]] = bounds_2[diffs2_index[i]]
        ProgressMeter.next!(p)
    end

    if length(same_var_1_uniq_bounds) > 0 || length(diff1_bounds) > 0 || length(diff2_bounds) > 0
        print_header(openfile, "VARIABLE BOUNDS")
    end

    p = ProgressUnknown("Writing in file bounds compare...")
    if compare_one_by_one
        if length(same_var_1_uniq_bounds) > 0
            write(openfile, "\tSAME VARIABLES\n")
            for key in keys(same_var_1_uniq_bounds)
                write(openfile, "\t", remove_quotes(key), "\n")
                write(openfile, "\t\t MODEL 1 => ", remove_quotes(string(same_var_1_uniq_bounds[key])) ,"\n")
                write(openfile, "\t\t MODEL 2 => ", remove_quotes(string(same_var_2_uniq_bounds[key])) ,"\n")
                ProgressMeter.next!(p)
            end
        end

        if length(diff1_bounds) > 0 || length(diff2_bounds) > 0
            write(openfile, "\tDIFFERENT VARIABLES:\n")
            if length(diff1_bounds) > 0
                write(openfile, "\tMODEL 1:\n")
                for key in keys(diff1_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff1_bounds[key])) ,"\n")
                    ProgressMeter.next!(p)
                end
            end
            if length(diff2_bounds) > 0
                write(openfile, "\tMODEL 2:\n")
                for key in keys(diff2_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff2_bounds[key])) ,"\n")
                    ProgressMeter.next!(p)
                end
            end
        end
    else
        if length(same_var_1_uniq_bounds) > 0 || length(diff1_bounds) > 0
            write(openfile, "\tMODEL 1:\n")
            if length(same_var_1_uniq_bounds) > 0
                for key in keys(same_var_1_uniq_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(same_var_1_uniq_bounds[key])) ,"\n")
                    ProgressMeter.next!(p)
                end
            end
            if length(diff1_bounds) > 0
                for key in keys(diff1_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff1_bounds[key])) ,"\n")
                    ProgressMeter.next!(p)
                end
            end
        end

        if length(same_var_2_uniq_bounds) > 0 || length(diff2_bounds) > 0
            write(openfile, "\tMODEL 2:\n")
            if length(same_var_2_uniq_bounds) > 0
                for key in keys(same_var_2_uniq_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(same_var_2_uniq_bounds[key])) ,"\n")
                    ProgressMeter.next!(p)
                end
            end
            if length(diff2_bounds) > 0
                for key in keys(diff2_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff2_bounds[key])) ,"\n")
                    ProgressMeter.next!(p)
                end
            end
        end
    end
end
