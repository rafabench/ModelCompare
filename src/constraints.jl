function compare_constraints(model1, model2, lists, openfile, tol)
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
                compare_expressions(all_cons_1[i][1],all_cons_2[j][1],model1,model2,openfile,tol)
                if typeof(all_sets_1[i][1]) == typeof(all_sets_2[j][1])
                    equal = 0
                    for field in fieldnames(typeof(all_sets_1[i][1]))
                        if abs(getfield(all_sets_1[i][1], field) - getfield(all_sets_2[j][1], field)) <= tol
                            equal += 1
                        end
                    end
                    if equal == length(fieldnames(typeof(all_sets_1[i][1])))
                         write(openfile, "SAME SET: ", replace(string(all_sets_1[i][1]), r"\"" => s""),"\n")
                    else
                        write(openfile, "DIFFERENT SETS","\n")
                        write(openfile, "MODEL 1: ", replace(string(all_sets_1[i][1]), r"\"" => s""),"\n")
                        write(openfile, "MODEL 2: ", replace(string(all_sets_2[j][1]), r"\"" => s""),"\n")
                    end
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