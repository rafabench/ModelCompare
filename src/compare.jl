function compare_models(; file1 = file1::String, file2 = file2::String, get_objective = true, get_constraints = true, get_bounds = true, outfile = outfile, tol = tol, separate_files = false, compare_one_by_one = true, verbose = true)
    println("ModelCompare: Comparing models...\n")
    if verbose
        println("File1:   $file1")
        println("File2:   $file2")
        println("Outfile: $outfile")
        println("Tol:     $tol")
    end

    if separate_files
        (basename, ext) = Base.Filesystem.splitext(outfile)
        outvar = "$(basename)_variables$(ext)"
        outobj = "$(basename)_objective$(ext)"
        outbnd = "$(basename)_bounds$(ext)"
        outcon = "$(basename)_constraints$(ext)"
    else
        mkpath(dirname(outfile))
        openfile = open(outfile,"w+")
    end

    model1 = readmodel(file1)
    model2 = readmodel(file2)

    # ~:~ Processing ~:~ #
    if separate_files
        println("Comparing Variables...")
        vardiff    = compare_variables(model1, model2)
        open(io -> printdiff(io, vardiff), outvar,"w+")

        if get_bounds
            println("Comparing Variable Bounds...")
            boundsdiff = compare_bounds(model1, model2, vardiff; tol = tol)
            open(io -> printdiff(io, boundsdiff), outbnd,"w+")
        end
    else
        println("Comparing Variables...")
        vardiff    = compare_variables(model1, model2)
        printdiff(openfile, vardiff)

        if get_bounds
            println("Comparing Variable Bounds...")
            boundsdiff = compare_bounds(model1, model2, vardiff; tol = tol)
            printdiff(openfile, boundsdiff)
        end
    end

    close(openfile)
    return

    equals_names = var_same
    equals_names_index_1 = filter(p -> first(p) in var_same, indices1)
    equals_names_index_2 = filter(p -> first(p) in var_same, indices2)
    diffs1 = var1
    diffs2 = var2
    diffs1_index = filter(p -> first(p) in var1, indices1)
    diffs2_index = filter(p -> first(p) in var2, indices2)

    if get_objective
        if separate_files
            open(outobj,"w+") do openobj
              compare_objective(model1,model2,lists, openobj, tol, compare_one_by_one)
            end
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
