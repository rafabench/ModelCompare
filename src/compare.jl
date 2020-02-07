function compare_models(; file1 = file1::String, file2 = file2::String, get_bounds = true, outfile = outfile, tol = tol)
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
    compare_objective(model1,model2,lists, openfile, tol)
    
    if get_bounds
        write(openfile, "\n")
        compare_bounds(model1,model2,lists, openfile, tol)
    end

    write(openfile, "\n")
    compare_constraints(model1,model2,lists, openfile, tol)
    close(openfile)
end