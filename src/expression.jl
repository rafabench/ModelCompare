function compare_expressions(expr1, expr2, model1, model2, openfile, tol, print_constraint, name, compare_one_by_one, check_print_header)
    coefs1 = sort([[model1.var_to_name[t.variable],t.coefficient] for t in expr1.terms],by=x->x[1])
    coefs2 = sort([[model2.var_to_name[t.variable],t.coefficient] for t in expr2.terms],by=x->x[1])
    k,l = 1,1
    n1 = length(coefs1)
    n2 = length(coefs2)
    equals_exp = Dict()
    same_var_1 = Dict()
    same_var_2 = Dict()
    diff_var_1 = Dict()
    diff_var_2 = Dict()
    iter = 1
    if name == "OBJECTIVE"
        p = ProgressMeter.ProgressUnknown("Comparing objective...")
    end

    while true
        if k <= n1 && l <= n2
            if coefs1[k][1] == coefs2[l][1]
                if abs(coefs1[k][2] - coefs2[l][2]) <= tol
                    equals_exp[coefs1[k][1]] = coefs1[k][2]
                else
                    same_var_1[coefs1[k][1]] = coefs1[k][2]
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
        if name == "OBJECTIVE"
            ProgressMeter.next!(p)
        end
    end
    if compare_one_by_one
        if length(same_var_1) > 0 || length(diff_var_1) > 0 || length(same_var_2) > 0 || length(diff_var_2) > 0
            write(openfile, "\n")
            if check_print_header 
                print_header(openfile, "CONSTRAINTS")
                check_print_header = false
            end
            if name == "OBJECTIVE"
                print_header(openfile, "OBJECTIVE")
            else
                write(openfile, "CONSTRAINT: ", name,"\n")
            end
            print_constraint = false
        end
        if length(same_var_1) > 0
            write(openfile, "\tSAME VARIABLES\n")
            for key in keys(same_var_1)
                write(openfile, "\t", remove_quotes(key), "\n")
                write(openfile, "\t\t MODEL 1 => ", remove_quotes(string(same_var_1[key])) ,"\n")
                write(openfile, "\t\t MODEL 2 => ", remove_quotes(string(same_var_2[key])) ,"\n")
            end
        end

        if length(diff_var_1) > 0 || length(diff_var_2) > 0
            write(openfile, "\tDIFFERENT VARIABLES:\n")
            if length(diff_var_1) > 0
                write(openfile, "\tMODEL 1:\n")
                for key in keys(diff_var_1)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff_var_1[key])) ,"\n")
                end
            end
            if length(diff_var_2) > 0
                write(openfile, "\tMODEL 2:\n")
                for key in keys(diff_var_2)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff_var_2[key])) ,"\n")
                end
            end
        end
    else
        if length(same_var_1) > 0 || length(diff_var_1) > 0 || length(same_var_2) > 0 || length(diff_var_2) > 0
            if check_print_header 
                print_header(openfile, "CONSTRAINTS")
                check_print_header = false
            end
            if name == "OBJECTIVE"
                print_header(openfile, "OBJECTIVE")
            else
                write(openfile, "CONSTRAINT: ", name,"\n")
            end
            print_constraint = false
        end
        if length(same_var_1) > 0 || length(diff_var_1) > 0
            write(openfile, "\tMODEL 1:\n")
            if length(same_var_1) > 0
                for key in keys(same_var_1)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(same_var_1[key])) ,"\n")
                end
            end
            if length(diff_var_1) > 0
                for key in keys(diff_var_1)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff_var_1[key])) ,"\n")
                end
            end
        end
        if length(same_var_2) > 0 || length(diff_var_2) > 0
            write(openfile, "\tMODEL 2:\n")
            if length(same_var_2) > 0
                for key in keys(same_var_2)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(same_var_2[key])) ,"\n")
                end
            end
            if length(diff_var_2) > 0
                for key in keys(diff_var_2)
                    write(openfile, "\t\t", remove_quotes(key), " => ", remove_quotes(string(diff_var_2[key])) ,"\n")
                end
            end
        end
    end
    return print_constraint, check_print_header
end