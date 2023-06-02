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
        )

    # ~:~ Processing ~:~ #
    vardiff    = compare_variables(model1, model2)
    boundsdiff = compare_bounds(model1, model2, vardiff; tol = tol)
    objectivediff = compare_objective(model1, model2; tol = tol)
    constraintsdiff = compare_constraints(model1, model2; tol = tol)

    return (; variables = vardiff,
              bounds    = boundsdiff,
              objective = objectivediff,
              constraints = constraintsdiff
           )
end

function print_compare(outfile::String, 
        vdiff::VariablesDiff,
        bdiff::BoundsDiff,
        objdiff::ObjectiveDiff,
        cdiff::ConstraintElementsDiff;
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

        println("Comparing Objective Function...")
        open(io -> printdiff(io, objdiff; one_by_one = one_by_one), outobj; write = true)

        println("Comparing Constraints...")
        open(io -> printdiff(io, cdiff; one_by_one = one_by_one), outcon; write = true)
    else
        open(outfile; write = true) do io
            println("Comparing Variables...")
            printdiff(io, vdiff)

            println("Comparing Variable Bounds...")
            printdiff(io, bdiff; one_by_one = true)

            println("Comparing Objective Function...")
            printdiff(io, objdiff; one_by_one = true)

            println("Comparing Constraints...")
            printdiff(io, cdiff; one_by_one = true)
        end
    end
end

function compare_models(file1, file2;
        tol            :: Float64,
        outfile        :: String,
        verbose        :: Bool   = true,
        one_by_one     :: Bool   = true,
        separate_files :: Bool   = false,
        )
    println("ModelCompare: Comparing models...\n")
    if verbose
        println("File1:   $file1")
        println("File2:   $file2")
        println("Outfile: $outfile")
        println("Tol:     $tol")
    end

    model1, model2 = readmodel(file1), readmodel(file2)
    result = compare(model1, model2; tol = tol)

    print_compare(outfile, result.variables, result.bounds, result.objective, result.constraints;
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
    call_compare(ARGS)
    return 0
end
