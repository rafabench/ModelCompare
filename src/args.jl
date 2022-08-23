function parse_commandline(args)
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--tol", "-t"
            help = "Tolerance of comparison"
            arg_type = Float64
            default = 1e-3
        "--different-files"
            help = "Print results in different files: variables, bounds, objective, constraints"
            action = :store_true
        "--verbose", "-v"
            help = "Verbose"
            action = :store_true
        "--output", "-o"
            help = "Output file path"
            arg_type = String
            default = Sys.iswindows() ? pwd()*"\\compare.txt" : pwd()*"/compare.txt"
        "--file1"
            help = "Path of the first optimization file. The default dir output will be the dir of this file."
            required = true
        "--file2"
            help = "Path of the second optimization file"
            required = true
    end

    return ArgParse.parse_args(args, s)
end