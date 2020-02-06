function read_from_file(file1::String, file2::String)
    model1 = MOI.FileFormats.Model(filename = file1)
    MOI.read_from_file(model1, file1)
    model2 = MOI.FileFormats.Model(filename = file2)
    MOI.read_from_file(model2, file2)
    return model1,model2
end

function compare_variables(all_variables_1, all_variables_2, openfile)
    n_var_1 = length(all_variables_1)
    n_var_2 = length(all_variables_2)
    equals_names = []
    equals_names_index_1 = []
    equals_names_index_2 = []
    diffs1 = []
    diffs2 = []
    diffs1_index = []
    diffs2_index = []
    write(openfile, "VARIABLE NAMES:\n")
    i,j = 1,1
    equals = []
    while true
        if i <= n_var_1 && j <= n_var_2
            if all_variables_1[i][2] == all_variables_2[j][2]
                push!(equals_names, all_variables_1[i][2])
                push!(equals_names_index_1, all_variables_1[i][1])
                push!(equals_names_index_2, all_variables_2[j][1])
                i += 1
                j += 1
            elseif all_variables_1[i][2] > all_variables_2[j][2]
                push!(diffs2, all_variables_2[j][2])
                push!(diffs2_index, all_variables_2[j][1])
                j += 1
            elseif all_variables_1[i][2] < all_variables_2[j][2]
                push!(diffs1, all_variables_1[i][2])
                push!(diffs1_index, all_variables_1[i][1])
                i += 1
            end
        elseif i > n_var_1 && !(j > n_var_2)
            push!(diffs2, all_variables_2[j][2])
            push!(diffs2_index, all_variables_2[j][1])
            j += 1
        elseif !(i > n_var_1) && j > n_var_2
            push!(diffs1, all_variables_1[i][2])
            push!(diffs1_index, all_variables_1[i][1])
            i += 1
        else
            break
        end
    end
    
    if length(equals_names) > 0
        write(openfile, "EQUAL:", replace(string(equals_names)[5:end-1], r"\"" => s""),"\n")
    end
    if length(diffs1) > 0
        write(openfile, "UNIQUE MODEL 1: ", replace(string(diffs1)[5:end-1], r"\"" => s""),"\n")
    end
    if length(diffs2) > 0
        write(openfile, "UNIQUE MODEL 2: ", replace(string(diffs2)[5:end-1], r"\"" => s""),"\n")
    end
    
    return [equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index]
end

function compare_expressions(expr1,expr2,model1,model2, openfile)
    coefs1 = sort([[model1.var_to_name[t.variable_index],t.coefficient] for t in expr1.terms],by=x->x[1])
    coefs2 = sort([[model2.var_to_name[t.variable_index],t.coefficient] for t in expr2.terms],by=x->x[1])
    k,l = 1,1
    n1 = length(coefs1)
    n2 = length(coefs2)
    equals_exp = Dict()
    same_var_1 = Dict()
    same_var_2 = Dict()
    diff_var_1 = Dict()
    diff_var_2 = Dict()
    iter = 1
    while true
        if k <= n1 && l <= n2
            if coefs1[k][1] == coefs2[l][1]
                if coefs1[k][2] == coefs2[l][2]
                    equals_exp[coefs1[k][1]] = coefs1[k][2]
                else
                    same_var_1[coefs1[k][1]] = coefs1[l][2]
                    same_var_2[coefs2[l][1]] = coefs2[l][2]
                end
                k += 1
                l += 1
            elseif coefs1[k][1] > coefs2[l][1]
                diff_var_2[coefs2[l][1]] = coefs2[l][2]
                l += 1
            elseif coefs1[k][1] < coefs2[l][1]
                diff_var_1[coefs1[k][1]] = coefs1[k][2]
                k += 1
            end
        elseif k > n1 && !(l > n2)
            diff_var_2[coefs2[l][1]] = coefs2[l][2]
            l += 1
        elseif !(k > n1) && l > n2
            diff_var_1[coefs1[k][1]] = coefs1[k][2]
            k += 1
        else
            break
        end
    end
    if length(equals_exp) > 0 || length(same_var_1) > 0 || length(same_var_2) > 0
        write(openfile, "COEFFICIENTS SAME VARIABLES: ","\n")
        if length(equals_exp) > 0
            write(openfile, "EQUALS: \n", replace(string(equals_exp)[15:end-1], r"\"" => s""),"\n")
        end
        if length(same_var_1) > 0
            write(openfile, "MODEL 1: \n", replace(string(same_var_1)[15:end-1], r"\"" => s""),"\n")
        end
        if length(same_var_2) > 0
            write(openfile, "MODEL 2: \n", replace(string(same_var_2)[15:end-1], r"\"" => s""),"\n")
        end
    end
    if length(diff_var_1) > 0 || length(diff_var_2) > 0
        write(openfile, "COEFFICIENTS DIFFERENT VARIABLES: ","\n")
        if length(diff_var_1) > 0
            write(openfile, "MODEL 1: \n", replace(string(diff_var_1)[15:end-1], r"\"" => s""),"\n")
        end
        if length(diff_var_2) > 0
            write(openfile, "MODEL 2: \n", replace(string(diff_var_2)[15:end-1], r"\"" => s""),"\n")
        end
    end
end

function compare_objective(model1,model2, lists, openfile)
    write(openfile, "OBJECTIVE: \n")
    equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index = lists
    
    if MOI.get(model1,MOI.ObjectiveSense()) == MOI.get(model2,MOI.ObjectiveSense())
        write(openfile, "EQUAL SENSE: ", string(MOI.get(model2,MOI.ObjectiveSense())),"\n")
    else
        write(openfile, "UNIQUE SENSE MODEL 1: ", string(MOI.get(model2,MOI.ObjectiveSense())),"\n")
        write(openfile, "UNIQUE SENSE MODEL 2: ", string(MOI.get(model2,MOI.ObjectiveSense())),"\n")
    end
    
    n_var_1 = MOI.get(model1,MOI.NumberOfVariables())
    n_var_2 = MOI.get(model2,MOI.NumberOfVariables())
    attr1 = MOI.get(model1, MOI.ObjectiveFunctionType())
    attr2 = MOI.get(model2, MOI.ObjectiveFunctionType())
    objective1 = MOI.get(model1,MOI.ObjectiveFunction{attr1}())
    objective2 = MOI.get(model2,MOI.ObjectiveFunction{attr2}())
    
    if attr1 != attr2
        write(openfile, "OBJECTIVE TYPES ARE DIFFERENT:","\n")
        write(openfile, "MODEL 1: ",attr1,"\n")
        write(openfile, "MODEL 2: ",attr2,"\n")
    else
        compare_expressions(objective1,objective2,model1,model2,openfile)
    end
end

function compare_bounds(model1,model2,lists, openfile)
    equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index = lists
    
    bounds_1 = []
    bounds_2 = []
    
    n_var_1 = MOI.get(model1,MOI.NumberOfVariables())
    n_var_2 = MOI.get(model2,MOI.NumberOfVariables())
    
    for i = 1:n_var_1
        if MOI.is_valid(model1,MOI.ConstraintIndex{MOI.SingleVariable,MOI.ZeroOne}(i))
            push!(bounds_1, "Binary")
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.SingleVariable,MOI.Integer}(i))
            push!(bounds_1, "Integer")
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.SingleVariable,MOI.EqualTo}(i))
            value = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.EqualTo}(i)).value
            push!(bounds_1, "[" * string(value) * "," * string(value) * "]")
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.SingleVariable,MOI.GreaterThan}(i))
            lower_bound = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.GreaterThan}(i)).lower
            push!(bounds_1, "["* string(lower_bound) * ",Inf)" )
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.SingleVariable,MOI.LessThan}(i))
            upper_bound = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.LessThan}(i)).upper
            push!(bounds_1, " (-Inf," * string(upper_bound) * "]" )
        elseif MOI.is_valid(model1,MOI.ConstraintIndex{MOI.SingleVariable,MOI.Interval}(i))
            upper_bound = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.Interval}(i)).upper
            lower_bound = MOI.get(model1,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.Interval}(i)).lower
            push!(bounds_1, "[" * string(lower_bound) * "," * string(upper_bound) * "]" )
        else
            push!(bounds_1, "(-Inf,Inf)")
        end
    end
    for i = 1:n_var_2
        if MOI.is_valid(model2,MOI.ConstraintIndex{MOI.SingleVariable,MOI.ZeroOne}(i))
            push!(bounds_2, "Binary")
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.SingleVariable,MOI.Integer}(i))
            push!(bounds_2, "Integer")
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.SingleVariable,MOI.EqualTo}(i))
            value = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.EqualTo}(i)).value
            push!(bounds_2, "[" * string(value) * "," * string(value) * "]")
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.SingleVariable,MOI.GreaterThan}(i))
            lower_bound = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.GreaterThan}(i)).lower
            push!(bounds_2, "["* string(lower_bound) * ",Inf)" )
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.SingleVariable,MOI.LessThan}(i))
            upper_bound = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.LessThan}(i)).upper
            push!(bounds_2, "(-Inf," * string(upper_bound) * "]" )
        elseif MOI.is_valid(model2,MOI.ConstraintIndex{MOI.SingleVariable,MOI.Interval}(i))
            upper_bound = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.Interval}(i)).upper
            lower_bound = MOI.get(model2,MOI.ConstraintSet(), MOI.ConstraintIndex{MOI.SingleVariable,MOI.Interval}(i)).lower
            push!(bounds_2, "[" * string(lower_bound) * "," * string(upper_bound) * "]" )
        else
            push!(bounds_2, "(-Inf,Inf)")
        end
    end
    equal_bounds = Dict()
    same_var_1_uniq_bounds = Dict()
    same_var_2_uniq_bounds = Dict()
    for i = 1:length(equals_names_index_1)
        if bounds_1[equals_names_index_1[i]] == bounds_2[equals_names_index_2[i]]
            equal_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]]
        else 
            same_var_1_uniq_bounds[equals_names[i]] = bounds_1[equals_names_index_1[i]]
            same_var_2_uniq_bounds[equals_names[i]] = bounds_2[equals_names_index_2[i]]
        end
    end
    if length(equal_bounds) > 0 || length(same_var_1_uniq_bounds) > 0 || length(same_var_2_uniq_bounds) > 0 
        write(openfile, "VARIABLE BOUNDS SAME VARIABLES:","\n")
        if length(equal_bounds) > 0
            write(openfile, "EQUALS: \n", replace(string(equal_bounds)[15:end-1], r"\"" => s""),"\n")
        end
        if length(same_var_1_uniq_bounds) > 0
            write(openfile, "UNIQUE MODEL 1: \n", replace(string(same_var_1_uniq_bounds)[15:end-1], r"\"" => s""),"\n")
        end
        if length(same_var_2_uniq_bounds) > 0
            write(openfile, "UNIQUE MODEL 2: \n", replace(string(same_var_2_uniq_bounds)[15:end-1], r"\"" => s""),"\n")
        end
    end

    println()
    diff1_bounds = Dict()
    diff2_bounds = Dict()
    for i = 1:length(diffs1_index)
        diff1_bounds[diffs1[i]] = bounds_1[diffs1_index[i]]
    end
    for i = 1:length(diffs2_index)
        diff2_bounds[diffs2[i]] = bounds_2[diffs2_index[i]]
    end
    if length(diff1_bounds) > 0 || length(diff2_bounds) > 0
        write(openfile, "VARIABLE BOUNDS DIFFERENT VARIABLES:","\n")
        if length(diff1_bounds) > 0
            write(openfile, "MODEL 1: \n", replace(string(diff1_bounds)[15:end-1], r"\"" => s""),"\n")
        end
        if length(diff2_bounds) > 0
            write(openfile, "MODEL 2: \n", replace(string(diff2_bounds)[15:end-1], r"\"" => s""),"\n")
        end
    end
end

function compare_constraints(model1,model2,lists, openfile)
    sorted_cons_1 = sort(collect(model1.con_to_name), by=x->x[2])
    sorted_cons_2 = sort(collect(model2.con_to_name), by=x->x[2])
    equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index = lists
    all_cons_1 = [[MOI.get(model1,MOI.ConstraintFunction(),con[1]),con[2]] for con in sorted_cons_1]
    all_cons_2 = [[MOI.get(model2,MOI.ConstraintFunction(),con[1]),con[2]] for con in sorted_cons_2]
    all_sets_1 = [[MOI.get(model1,MOI.ConstraintSet(),con[1]),con[2]] for con in sorted_cons_1]
    all_sets_2 = [[MOI.get(model2,MOI.ConstraintSet(),con[1]),con[2]] for con in sorted_cons_2]
    n_cons_1 = length(all_cons_1)
    n_cons_2 = length(all_cons_2)
    equal_cons = []
    diff_1_cons = []
    diff_2_cons = []
    i,j = 1,1
    while true
        if i <= n_cons_1 && j <= n_cons_2
            if all_cons_1[i][2] == all_cons_2[j][2]
                push!(equal_cons, all_cons_2[j][2])
                write(openfile, "CONSTRAINT: ", all_cons_1[i][2],"\n")
                compare_expressions(all_cons_1[i][1],all_cons_2[j][1],model1,model2,openfile)
                if all_sets_1[i][1] == all_sets_2[j][1]
                    write(openfile, "SAME SET: ", replace(string(all_sets_1[i][1]), r"\"" => s""),"\n")
                else
                    write(openfile, "DIFFERENT SETS","\n")
                    write(openfile, "MODEL 1: ", replace(string(all_sets_1[i][1]), r"\"" => s""),"\n")
                    write(openfile, "MODEL 2: ", replace(string(all_sets_2[j][1]), r"\"" => s""),"\n")
                end
                write(openfile, "\n")
                i += 1
                j += 1
            elseif all_cons_1[i][2] > all_cons_2[j][2]
                push!(diff_2_cons, all_cons_2[j][2])
                j += 1
            elseif all_cons_1[i][2] < all_cons_2[j][2]
                push!(diff_1_cons, all_cons_1[i][2])
                i += 1
            end
        elseif i > n_cons_1 && !(j > n_cons_2)
            push!(diff_2_cons, all_cons_2[j][2])
            j += 1
        elseif !(i > n_cons_1) && j > n_cons_2
            push!(diff_1_cons, all_cons_1[i][2])
            i += 1
        else
            break
        end
    end
end

function compare_models(; file1 = file1::String, file2 = file2::String, get_bounds = true, outfile = outfile)
    openfile = open(outfile,"w+")
    model1,model2 = read_from_file(file1, file2)
    sorted_variable_1 = sort(collect(model1.var_to_name), by=x->x[2])
    sorted_variable_2 = sort(collect(model2.var_to_name), by=x->x[2])
    all_variables_1 = [[var[1].value,var[2]] for var in sorted_variable_1]
    all_variables_2 = [[var[1].value,var[2]] for var in sorted_variable_2]
    n_var_1 = length(all_variables_1)
    n_var_2 = length(all_variables_2)
    
    lists = compare_variables(all_variables_1, all_variables_2, openfile)
    equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index = lists
    write(openfile, "\n")
    compare_objective(model1,model2,lists, openfile)
    
    if get_bounds
        write(openfile, "\n")
        compare_bounds(model1,model2,lists, openfile)
    end
    
    write(openfile, "\n")
    compare_constraints(model1,model2,lists, openfile)
    close(openfile)
end