function compare_models(; file1 = file1::String, file2 = file2::String, get_objective = true, get_constraints = true, get_bounds = true, outfile = outfile, tol = tol, separate_files = false, compare_one_by_one = true, verbose = true)
    println("ModelComparator: Comparing models...\n")
    if verbose
        println("File1:   $file1")
        println("File2:   $file2")
        println("Outfile: $outfile")
        println("Tol:     $tol")
    end
    if separate_files
        outvar = outfile[1:end-4] * "_variables.txt"
        outobj = outfile[1:end-4] * "_objective.txt"
        outbnd = outfile[1:end-4] * "_bounds.txt"
        outcon = outfile[1:end-4] * "_constraints.txt"
    else
        if !isdir(dirname(outfile))
            mkdir(dirname(outfile))
        end
        openfile = open(outfile,"w+")
    end 
    model1,model2 = read_from_file(file1, file2)
    sorted_variable_1 = sort(collect(model1.var_to_name), by=x->x[2])
    sorted_variable_2 = sort(collect(model2.var_to_name), by=x->x[2])
    all_variables_1 = [[var[1].value,var[2]] for var in sorted_variable_1]
    all_variables_2 = [[var[1].value,var[2]] for var in sorted_variable_2]
    n_var_1 = length(all_variables_1)
    n_var_2 = length(all_variables_2)
    
    if separate_files
        openvar = open(outvar,"w+")
        lists = compare_variables(all_variables_1, all_variables_2, openvar)
    else
        lists = compare_variables(all_variables_1, all_variables_2, openfile)
    end
    equals_names,equals_names_index_1,equals_names_index_2,diffs2,diffs2_index,diffs1,diffs1_index = lists
    if get_objective
        if separate_files
            openobj = open(outobj,"w+")
            compare_objective(model1,model2,lists, openobj, tol, compare_one_by_one)
        else
            compare_objective(model1,model2,lists, openfile, tol, compare_one_by_one)
        end
    end

    if get_bounds
        if separate_files
            openbnd = open(outbnd,"w+")
            compare_bounds(model1,model2,lists, openbnd, tol, compare_one_by_one)
        else
            compare_bounds(model1,model2,lists, openfile, tol, compare_one_by_one)
        end
    end
    
    if get_constraints
        if separate_files
            opencon = open(outcon,"w+")
            compare_constraints(model1,model2,lists, opencon, tol, compare_one_by_one)
        else
            compare_constraints(model1,model2,lists, openfile, tol, compare_one_by_one)
        end
    end
    
    if separate_files
        close(openvar)
        if get_objective
            close(openobj)
        end
        if get_bounds
            close(openbnd)
        end
        if get_constraints
            close(opencon)
        end
    else
        close(openfile)
    end
    return 0
end

function call_compare(args)
    parsed_args = parse_commandline(args)
    file1 = parsed_args["file1"]
    dirfile1 = dirname(file1)
    file2 = parsed_args["file2"]
    outfile = joinpath(dirfile1,parsed_args["output"])
    tol = parsed_args["tol"]
    separate_files = parsed_args["different-files"]
    compare_one_by_one = true
    verbose = parsed_args["verbose"]
    return compare_models(
        file1 = file1,
        file2 = file2,
        get_objective = true,
        get_constraints = true,
        get_bounds = true,
        outfile = outfile,
        tol = tol,
        separate_files = separate_files,
        compare_one_by_one = true,
        verbose = verbose
    )
end

function julia_main()::Cint
    return call_compare(ARGS)
end