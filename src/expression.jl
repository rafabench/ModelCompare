function compare_expressions(expr1, expr2, model1, model2, openfile, tol)
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