function compare_bounds(model1, model2, lists, openfile, tol, compare_one_by_one)
    equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index = lists
    
    bounds_1 = []
    bounds_2 = []
    
    n_var_1 = MOI.get(model1,MOI.NumberOfVariables())
    n_var_2 = MOI.get(model2,MOI.NumberOfVariables())
    
    for i = 1:n_var_1
        if MOI.is_valid(model1,MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne}(i))
            push!(bounds_1, ["ZeroOne","Binary"])
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.VariableIndex,MOI.Integer}(i))
            push!(bounds_1, ["Integer","Integer"])
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo}(i))
            value = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo}(i)).value
            push!(bounds_1, ["EqualTo", value ,"[" * string(value) * "," * string(value) * "]"])
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan}(i))
            lower_bound = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan}(i)).lower
            push!(bounds_1,["GreaterThan",lower_bound ,"["* string(lower_bound) * ",Inf)" ])
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan}(i))
            upper_bound = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan}(i)).upper
            push!(bounds_1,["LessThan",upper_bound, " (-Inf," * string(upper_bound) * "]" ])
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval}(i))
            upper_bound = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval}(i)).upper
            lower_bound = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval}(i)).lower
            push!(bounds_1,["Interval",upper_bound ,lower_bound ,"[" * string(lower_bound) * "," * string(upper_bound) * "]"] )
        else
            push!(bounds_1, "(-Inf,Inf)")
        end
    end
    for i = 1:n_var_2
        if MOI.is_valid(model2,MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne}(i))
            push!(bounds_2, ["ZeroOne","Binary"])
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.VariableIndex,MOI.Integer}(i))
            push!(bounds_2, ["Integer","Integer"])
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo}(i))
            value = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo}(i)).value
            push!(bounds_2, ["EqualTo", value ,"[" * string(value) * "," * string(value) * "]"])
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan}(i))
            lower_bound = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan}(i)).lower
            push!(bounds_2,["GreaterThan",lower_bound ,"["* string(lower_bound) * ",Inf)" ])
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan}(i))
            upper_bound = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan}(i)).upper
            push!(bounds_2,["LessThan",upper_bound, " (-Inf," * string(upper_bound) * "]" ])
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval}(i))
            upper_bound = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval}(i)).upper
            lower_bound = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval}(i)).lower
            push!(bounds_2,["Interval",upper_bound ,lower_bound ,"[" * string(lower_bound) * "," * string(upper_bound) * "]"] )
        else
            push!(bounds_2, "(-Inf,Inf)")
        end
    end
    equal_bounds = Dict()
    same_var_1_uniq_bounds = Dict()
    same_var_2_uniq_bounds = Dict()
    for i = 1:length(equals_names_index_1)
        if bounds_1[equals_names_index_1[i]][1] == bounds_2[equals_names_index_2[i]][1]
            if bounds_1[equals_names_index_1[i]][1] == "ZeroOne" 
                equal_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
            elseif bounds_1[equals_names_index_1[i]][1] == "Integer"
                equal_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
            elseif bounds_1[equals_names_index_1[i]][1] == "EqualTo"
                if abs(bounds_1[equals_names_index_1[i]][2] - bounds_1[equals_names_index_1[i]][2]) <= tol
                    equal_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                else
                    same_var_1_uniq_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                    same_var_2_uniq_bounds[equals_names[i]] = bounds_2[equals_names_index_2[i]][end]
                end
            elseif bounds_1[equals_names_index_1[i]][1] == "GreaterThan"
                if abs(bounds_1[equals_names_index_1[i]][2] - bounds_1[equals_names_index_1[i]][2]) <= tol
                    equal_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                else
                    same_var_1_uniq_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                    same_var_2_uniq_bounds[equals_names[i]] = bounds_2[equals_names_index_2[i]][end]
                end
            elseif bounds_1[equals_names_index_1[i]][1] == "LessThan"
                if abs(bounds_1[equals_names_index_1[i]][2] - bounds_1[equals_names_index_1[i]][2]) <= tol
                    equal_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                else
                    same_var_1_uniq_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                    same_var_2_uniq_bounds[equals_names[i]] = bounds_2[equals_names_index_2[i]][end]
                end
            elseif bounds_1[equals_names_index_1[i]][1] == "Interval"
                if (abs(bounds_1[equals_names_index_1[i]][2] - bounds_1[equals_names_index_1[i]][2]) <= tol) && (abs(bounds_1[equals_names_index_1[i]][3] - bounds_1[equals_names_index_1[i]][3]) <= tol)
                    equal_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                else
                    same_var_1_uniq_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                    same_var_2_uniq_bounds[equals_names[i]] = bounds_2[equals_names_index_2[i]][end]
                end
            end
        else 
                same_var_1_uniq_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]][end]
                same_var_2_uniq_bounds[equals_names[i]] = bounds_2[equals_names_index_2[i]][end]
        end
    end

    diff1_bounds = Dict()
    diff2_bounds = Dict()
    for i = 1:length(diffs1_index)
        diff1_bounds[diffs1[i]] = bounds_1[diffs1_index[i]][end]
    end

    if length(same_var_1_uniq_bounds) > 0 || length(diff1_bounds) > 0 || length(diff2_bounds) > 0
        print_header(openfile, "VARIABLE BOUNDS")
    end

    if compare_one_by_one
        if length(same_var_1_uniq_bounds) > 0
            write(openfile, "\tSAME VARIABLES\n")
            for key in keys(same_var_1_uniq_bounds)
                write(openfile, "\t", remove_quotes(key), "\n")
                write(openfile, "\t\t MODEL 1 => ", remove_quotes(string(same_var_1_uniq_bounds[key])) ,"\n")
                write(openfile, "\t\t MODEL 2 => ", remove_quotes(string(same_var_2_uniq_bounds[key])) ,"\n")
            end
        end

        if length(diff1_bounds) > 0 || length(diff2_bounds) > 0
            write(openfile, "\tDIFFERENT VARIABLES:\n")
            if length(diff1_bounds) > 0
                write(openfile, "\tMODEL 1:\n")
                for key in keys(diff1_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff1_bounds[key])) ,"\n")
                end
            end
            if length(diff2_bounds) > 0
                write(openfile, "\tMODEL 2:\n")
                for key in keys(diff2_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff2_bounds[key])) ,"\n")
                end
            end
        end
    else
        if length(same_var_1_uniq_bounds) > 0 || length(diff1_bounds) > 0
            write(openfile, "\tMODEL 1:\n")
            if length(same_var_1_uniq_bounds) > 0
                for key in keys(same_var_1_uniq_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(same_var_1_uniq_bounds[key])) ,"\n")
                end
            end
            if length(diff1_bounds) > 0
                for key in keys(diff1_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff1_bounds[key])) ,"\n")
                end
            end
        end

        if length(same_var_2_uniq_bounds) > 0 || length(diff2_bounds) > 0
            write(openfile, "\tMODEL 2:\n")
            if length(same_var_2_uniq_bounds) > 0
                for key in keys(same_var_2_uniq_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(same_var_2_uniq_bounds[key])) ,"\n")
                end
            end
            if length(diff2_bounds) > 0
                for key in keys(diff2_bounds)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff2_bounds[key])) ,"\n")
                end
            end
        end
    end
end