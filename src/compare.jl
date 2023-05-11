function compare(file1::String, file2::String; kws...)
    return compare(readmodel(file1), readmodel(file2); kws...)
end

"""
    compare(model1, model2)

Examine the two models and return a report of their
differences and similarities.
"""
function compare(model1::MOI.ModelLike, model2::MOI.ModelLike;
        tol :: Float64,
        get_objective   ::Bool = true,
        get_constraints ::Bool = true,
        get_bounds      ::Bool = true,
        )

    # ~:~ Processing ~:~ #
    vardiff    = compare_variables(model1, model2)
    boundsdiff = compare_bounds(model1, model2, vardiff; tol = tol)

    return (; variables = vardiff,
              bounds    = boundsdiff,
           )

    #########################################
    # TODO: Decouple Constraints & Objective
    #########################################
    if get_objective
        if separate_files
            open(outobj,"w+") do openobj
              compare_objective(model1,model2,lists, openobj, tol, compare_one_by_one)
            end
        else
            compare_objective(model1,model2,lists, openfile, tol, compare_one_by_one)
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
        if get_constraints
            close(opencon)
        end
    else
        close(openfile)
    end
    return 0
end

function print_compare(outfile::String, vdiff::VariablesDiff, bdiff::BoundsDiff;
        verbose        :: Bool = true,
        one_by_one     :: Bool = true,
        separate_files :: Bool = false
        )
    mkpath(dirname(outfile))

    if separate_files
        (basename, ext) = Base.Filesystem.splitext(outfile)
        outvar = "$(basename)_variables$(ext)"
        outbnd = "$(basename)_bounds$(ext)"
        outobj = "$(basename)_objective$(ext)"
        outcon = "$(basename)_constraints$(ext)"

        if verbose
            println("Variables:   $(outvar)")
            println("Bounds:      $(outbnd)")
            println("Objective:   $(outobj)")
            println("Constraints: $(outcon)")
        end

        println("Comparing Variables...")
        open(io -> printdiff(io, vdiff), outvar; write = true)

        println("Comparing Variable Bounds...")
        open(io -> printdiff(io, bdiff; one_by_one = one_by_one), outbnd; write = true)
    else
        open(outfile; write = true) do io
            println("Comparing Variables...")
            printdiff(io, vdiff)

            println("Comparing Variable Bounds...")
            printdiff(io, bdiff; one_by_one = true)
        end
    end
end

function compare_models(model1, model2;
        tol            :: Float64,
        outfile        :: String,
        verbose        :: Bool   = true,
        one_by_one     :: Bool   = true,
        separate_files :: Bool   = false,
        )
    println("ModelCompare: Comparing models...\n")
    if verbose
        println("File1:   $model1")
        println("File2:   $model2")
        println("Outfile: $outfile")
        println("Tol:     $tol")
    end

    result = compare(model1, model2; tol = tol)

    print_compare(outfile, result.variables, result.bounds;
        separate_files = separate_files,
        one_by_one     = one_by_one,
        verbose        = verbose,
    )

    return result
end

function call_compare(args)
    parsed_args     = parse_commandline(args)
    file1           = parsed_args["file1"]
    dirfile1        = dirname(file1)
    file2           = parsed_args["file2"]
    outfile         = joinpath(dirfile1,parsed_args["output"])
    tol             = parsed_args["tol"]
    separate_files  = parsed_args["different-files"]
    one_by_one      = true
    verbose         = parsed_args["verbose"]

    return compare_models(file1, file2;
        tol            = tol,
        outfile        = outfile,
        separate_files = separate_files,
        one_by_one     = one_by_one,
        verbose        = verbose
    )
end

function julia_main()::Cint
    return call_compare(ARGS)
end
