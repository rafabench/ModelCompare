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
    i,j = 1,1
    equals = []
    p = ProgressUnknown("Comparing variables...")
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
        next!(p)
    end
    
    #if length(equals_names) > 0
    #    write(openfile, "EQUAL:", remove_quotes(string(equals_names)[5:end-1]),"\n")
    #end
    p = ProgressUnknown("Writing in file variable compare...")
    
    if length(diffs1) > 0 || length(diffs2) > 0
        print_header(openfile, "VARIABLE NAMES")
        next!(p)
    end
    
    if length(diffs1) > 0
        write(openfile, "\tMODEL 1\n")
        for i = 1:length(diffs1)
            write(openfile,"\t\t", remove_quotes(diffs1[i]),"\n")
            next!(p)
        end
    end
    if length(diffs2) > 0
        write(openfile, "\tMODEL 2\n")
        for i = 1:length(diffs2)
            write(openfile,"\t\t", remove_quotes(diffs2[i]),"\n")
            next!(p)
        end
    end
    
    return [equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index]
end