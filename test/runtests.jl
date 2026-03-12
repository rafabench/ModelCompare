using Test
using ModelCompare
using MathOptInterface
const MOI = MathOptInterface

# Generate test model files
include(joinpath(@__DIR__, "generate_models.jl"))

# Model file paths
const MODEL1_LP  = joinpath(@__DIR__, "models", "model1.lp")
const MODEL2_LP  = joinpath(@__DIR__, "models", "model2.lp")
const MODEL1_MPS = joinpath(@__DIR__, "models", "model1.mps")
const MODEL2_MPS = joinpath(@__DIR__, "models", "model2.mps")
const MODEL_TOL1 = joinpath(@__DIR__, "models", "model_tol_1.mps")
const MODEL_TOL2 = joinpath(@__DIR__, "models", "model_tol_2.mps")
const BIGLP1_LP  = joinpath(@__DIR__, "models", "modelbiglp1.lp")
const BIGLP2_LP  = joinpath(@__DIR__, "models", "modelbiglp2.lp")
const BIGLP1_MPS = joinpath(@__DIR__, "models", "modelbiglp1.mps")
const BIGLP2_MPS = joinpath(@__DIR__, "models", "modelbiglp2.mps")

@testset "ModelCompare.jl" begin

    @testset "Utilities" begin
        @testset "readmodel — LP" begin
            m = ModelCompare.readmodel(MODEL1_LP)
            @test m isa MOI.ModelLike
        end

        @testset "readmodel — MPS" begin
            m = ModelCompare.readmodel(MODEL1_MPS)
            @test m isa MOI.ModelLike
        end

        @testset "partition — basic" begin
            inter, only_a, only_b = ModelCompare.partition([1, 2, 3], [2, 3, 4])
            @test sort(inter) == [2, 3]
            @test only_a == [1]
            @test only_b == [4]
        end

        @testset "partition — empty" begin
            inter, only_a, only_b = ModelCompare.partition(Int[], Int[])
            @test isempty(inter)
            @test isempty(only_a)
            @test isempty(only_b)
        end

        @testset "partition — identical" begin
            inter, only_a, only_b = ModelCompare.partition([1, 2], [1, 2])
            @test sort(inter) == [1, 2]
            @test isempty(only_a)
            @test isempty(only_b)
        end

        @testset "partition — disjoint" begin
            inter, only_a, only_b = ModelCompare.partition([1, 2], [3, 4])
            @test isempty(inter)
            @test sort(only_a) == [1, 2]
            @test sort(only_b) == [3, 4]
        end
    end

    @testset "compare_variables" begin
        @testset "LP format" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL2_LP)
            vdiff = compare_variables(m1, m2)
            @test vdiff isa ModelCompare.VariablesDiff
            # Model 1 unique vars
            @test "x" in vdiff.only_one
            @test "w" in vdiff.only_one
            @test "z_a" in vdiff.only_one
            @test length(vdiff.only_one) == 3
            # Model 2 unique vars
            @test "p" in vdiff.only_two
            @test "t" in vdiff.only_two
            @test "z_a_1_" in vdiff.only_two
            @test "z_a_2_" in vdiff.only_two
            @test "z_6_" in vdiff.only_two
            @test "z_7_" in vdiff.only_two
            @test "z_8_" in vdiff.only_two
            @test "z_9_" in vdiff.only_two
            @test "z_10_" in vdiff.only_two
            @test length(vdiff.only_two) == 9
            # Common vars
            @test "y_1_" in vdiff.in_both
            @test "y_2_" in vdiff.in_both
            @test "d" in vdiff.in_both
            @test "z_1_" in vdiff.in_both
        end

        @testset "MPS format" begin
            m1 = ModelCompare.readmodel(MODEL1_MPS)
            m2 = ModelCompare.readmodel(MODEL2_MPS)
            vdiff = compare_variables(m1, m2)
            @test vdiff isa ModelCompare.VariablesDiff
            @test !isempty(vdiff.only_one)
            @test !isempty(vdiff.only_two)
            @test !isempty(vdiff.in_both)
        end

        @testset "identical models" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL1_LP)
            vdiff = compare_variables(m1, m2)
            @test isempty(vdiff.only_one)
            @test isempty(vdiff.only_two)
            @test !isempty(vdiff.in_both)
        end
    end

    @testset "compare_bounds" begin
        @testset "LP format" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL2_LP)
            vdiff = compare_variables(m1, m2)
            bdiff = compare_bounds(m1, m2, vdiff; tol = 0.0)
            @test bdiff isa ModelCompare.BoundsDiff
            @test !isempty(bdiff.first)
            @test !isempty(bdiff.second)
            # Model 1 unique variable bounds
            @test haskey(bdiff.first, "w")
            @test haskey(bdiff.first, "x")
            @test haskey(bdiff.first, "z_a")
            # Check specific bound values
            @test bdiff.first["z_a"] == (25.0, 25.0)
        end

        @testset "2-arg convenience method" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL2_LP)
            bdiff = compare_bounds(m1, m2; tol = 0.0)
            @test bdiff isa ModelCompare.BoundsDiff
            @test haskey(bdiff.first, "w")
        end

        @testset "identical models — everything equal" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL1_LP)
            bdiff = compare_bounds(m1, m2; tol = 0.0)
            @test isempty(bdiff.first)
            @test isempty(bdiff.second)
            @test isempty(bdiff.both)
            @test !isempty(bdiff.equal)
        end

        @testset "tolerance effects" begin
            m1 = ModelCompare.readmodel(MODEL_TOL1)
            m2 = ModelCompare.readmodel(MODEL_TOL2)
            bdiff_tight = compare_bounds(m1, m2; tol = 1e-6)
            bdiff_loose = compare_bounds(m1, m2; tol = 10.0)
            @test length(bdiff_loose.equal) >= length(bdiff_tight.equal)
        end
    end

    @testset "compare_expressions" begin
        @testset "objective expressions — LP" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL2_LP)
            attr1 = MOI.get(m1, MOI.ObjectiveFunctionType())
            attr2 = MOI.get(m2, MOI.ObjectiveFunctionType())
            obj1 = MOI.get(m1, MOI.ObjectiveFunction{attr1}())
            obj2 = MOI.get(m2, MOI.ObjectiveFunction{attr2}())
            ediff = compare_expressions(obj1, obj2, m1, m2; tol = 0.0)
            @test ediff isa ModelCompare.ExpressionDiff
            # Variables only in model1 objective: x, z_a
            @test haskey(ediff.first, "x")
            @test haskey(ediff.first, "z_a")
            @test ediff.first["x"] == 2.0
            @test ediff.first["z_a"] == 1.0
            # Variables only in model2 objective: y_2_, z_3_, z_6_..z_10_, z_a_1_, z_a_2_, p
            @test haskey(ediff.second, "p")
            @test ediff.second["p"] == 3.0
            # Same variables with different coefficients
            @test haskey(ediff.both, "y_1_")
            @test ediff.both["y_1_"] == (3.0, 5.0)
            @test haskey(ediff.both, "d")
            @test ediff.both["d"] == (5.0, 1.0)
            # Equal variables (same coefficient in both)
            @test "z_1_" in ediff.equal
            @test "z_4_" in ediff.equal
            @test "z_5_" in ediff.equal
        end
    end

    @testset "compare_objective" begin
        @testset "LP format" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL2_LP)
            odiff = compare_objective(m1, m2; tol = 0.0)
            @test odiff isa ModelCompare.ObjectiveDiff
            @test odiff.sense == (MOI.MAX_SENSE, MOI.MAX_SENSE)
            @test !isempty(odiff.expression.first)
            @test !isempty(odiff.expression.second)
            @test !isempty(odiff.expression.both)
        end

        @testset "MPS format" begin
            m1 = ModelCompare.readmodel(MODEL1_MPS)
            m2 = ModelCompare.readmodel(MODEL2_MPS)
            odiff = compare_objective(m1, m2; tol = 0.0)
            @test odiff isa ModelCompare.ObjectiveDiff
            # MPS files use MIN_SENSE by default
            @test odiff.sense[1] == MOI.MIN_SENSE
            @test odiff.sense[2] == MOI.MIN_SENSE
        end

        @testset "identical models" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL1_LP)
            odiff = compare_objective(m1, m2; tol = 0.0)
            @test isempty(odiff.expression.first)
            @test isempty(odiff.expression.second)
            @test isempty(odiff.expression.both)
            @test !isempty(odiff.expression.equal)
        end
    end

    @testset "compare_constraints" begin
        @testset "LP format" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL2_LP)
            cdiff = compare_constraints(m1, m2; tol = 0.0)
            @test cdiff isa ModelCompare.ConstraintElementsDiff
            # Constraints in both: y_con, c1, z_con
            @test !isempty(cdiff.both) || !isempty(cdiff.equal)
            # model2 has unique constraint "zcon"
            @test !isempty(cdiff.second)
            @test haskey(cdiff.second, "zcon")
        end

        @testset "identical models" begin
            m1 = ModelCompare.readmodel(MODEL1_LP)
            m2 = ModelCompare.readmodel(MODEL1_LP)
            cdiff = compare_constraints(m1, m2; tol = 0.0)
            @test isempty(cdiff.both)
            @test isempty(cdiff.first)
            @test isempty(cdiff.second)
            @test !isempty(cdiff.equal)
        end

        @testset "tolerance effects" begin
            m1 = ModelCompare.readmodel(MODEL_TOL1)
            m2 = ModelCompare.readmodel(MODEL_TOL2)
            cdiff_tight = compare_constraints(m1, m2; tol = 1e-6)
            cdiff_loose = compare_constraints(m1, m2; tol = 10.0)
            @test length(cdiff_loose.equal) >= length(cdiff_tight.equal)
        end
    end

    @testset "compare_models (integration)" begin
        @testset "LP end-to-end" begin
            mktempdir() do dir
                outfile = joinpath(dir, "compare_lp.txt")
                result = compare_models(MODEL1_LP, MODEL2_LP;
                    outfile = outfile, tol = 0.0)
                @test result isa NamedTuple
                @test haskey(result, :variables)
                @test haskey(result, :bounds)
                @test haskey(result, :objective)
                @test haskey(result, :constraints)
                @test isfile(outfile)
                content = read(outfile, String)
                @test occursin("VARIABLE NAMES", content)
                @test occursin("VARIABLE BOUNDS", content)
                @test occursin("OBJECTIVE", content)
                @test occursin("CONSTRAINTS", content)
            end
        end

        @testset "MPS end-to-end" begin
            mktempdir() do dir
                outfile = joinpath(dir, "compare_mps.txt")
                result = compare_models(MODEL1_MPS, MODEL2_MPS;
                    outfile = outfile, tol = 0.0)
                @test result isa NamedTuple
                @test isfile(outfile)
            end
        end

        @testset "separate_files mode" begin
            mktempdir() do dir
                outfile = joinpath(dir, "compare.txt")
                compare_models(MODEL1_LP, MODEL2_LP;
                    outfile = outfile, tol = 0.0, separate_files = true, verbose = false)
                @test isfile(joinpath(dir, "compare_variables.txt"))
                @test isfile(joinpath(dir, "compare_bounds.txt"))
                @test isfile(joinpath(dir, "compare_objective.txt"))
                @test isfile(joinpath(dir, "compare_constraints.txt"))
            end
        end

        @testset "tolerance parameter" begin
            mktempdir() do dir
                out_tight = joinpath(dir, "tight.txt")
                out_loose = joinpath(dir, "loose.txt")
                r_tight = compare_models(MODEL_TOL1, MODEL_TOL2;
                    outfile = out_tight, tol = 1e-6, verbose = false)
                r_loose = compare_models(MODEL_TOL1, MODEL_TOL2;
                    outfile = out_loose, tol = 10.0, verbose = false)
                @test length(r_loose.bounds.equal) >= length(r_tight.bounds.equal)
            end
        end

        @testset "big LP models" begin
            mktempdir() do dir
                outfile = joinpath(dir, "compare_big.txt")
                result = compare_models(BIGLP1_LP, BIGLP2_LP;
                    outfile = outfile, tol = 0.0, verbose = false)
                @test result isa NamedTuple
                @test isfile(outfile)
            end
        end
    end

    @testset "sort_model" begin
        mktempdir() do dir
            # Copy model1.lp to temp dir
            src = MODEL1_LP
            dst = joinpath(dir, "model1.lp")
            cp(src, dst)
            sort_model(dst)
            sorted_file = dst * ".sorted"
            @test isfile(sorted_file)
            content = read(sorted_file, String)
            @test !isempty(content)
            @test occursin("MINIMIZE", content) || occursin("MAXIMIZE", content)
            @test occursin("SUBJECT TO:", content)
            @test occursin("BOUNDS:", content)
            @test occursin("End", content)

            # Verify constraint names in SUBJECT TO section are sorted
            lines = split(content, "\n")
            subj_start = findfirst(l -> occursin("SUBJECT TO:", l), lines)
            bounds_start = findfirst(l -> occursin("BOUNDS:", l), lines)
            if subj_start !== nothing && bounds_start !== nothing
                con_lines = lines[subj_start+1:bounds_start-1]
                con_names = String[]
                for l in con_lines
                    cm = match(r"^(\S+):", strip(l))
                    if cm !== nothing
                        push!(con_names, cm.captures[1])
                    end
                end
                if !isempty(con_names)
                    @test con_names == sort(con_names)
                end
            end
        end

        @testset "sort_model with MPS" begin
            mktempdir() do dir
                src = MODEL1_MPS
                dst = joinpath(dir, "model1.mps")
                # sort_model writes .sorted in LP format regardless
                # Just copy as .lp to sort
                dst_lp = joinpath(dir, "model1.lp")
                cp(MODEL1_LP, dst_lp)
                sort_model(dst_lp)
                sorted_file = dst_lp * ".sorted"
                @test isfile(sorted_file)
                content = read(sorted_file, String)
                @test !isempty(content)
            end
        end
    end

    @testset "printdiff (output formatting)" begin
        m1 = ModelCompare.readmodel(MODEL1_LP)
        m2 = ModelCompare.readmodel(MODEL2_LP)

        @testset "VariablesDiff" begin
            vdiff = compare_variables(m1, m2)
            io = IOBuffer()
            ModelCompare.printdiff(io, vdiff)
            output = String(take!(io))
            @test occursin("VARIABLE NAMES", output)
            @test occursin("Only MODEL 1", output)
            @test occursin("Only MODEL 2", output)
        end

        @testset "BoundsDiff" begin
            bdiff = compare_bounds(m1, m2; tol = 0.0)
            io = IOBuffer()
            ModelCompare.printdiff(io, bdiff; one_by_one = true)
            output = String(take!(io))
            @test occursin("VARIABLE BOUNDS", output)
        end

        @testset "ObjectiveDiff" begin
            odiff = compare_objective(m1, m2; tol = 0.0)
            io = IOBuffer()
            ModelCompare.printdiff(io, odiff; one_by_one = true)
            output = String(take!(io))
            @test occursin("OBJECTIVE", output)
        end

        @testset "ConstraintElementsDiff" begin
            cdiff = compare_constraints(m1, m2; tol = 0.0)
            io = IOBuffer()
            ModelCompare.printdiff(io, cdiff; one_by_one = true)
            output = String(take!(io))
            @test occursin("CONSTRAINTS", output)
        end
    end

    @testset "constraint_set_to_bound" begin
        @test ModelCompare.constraint_set_to_bound(MOI.LessThan(5.0)) == (typemin(Float64), 5.0)
        @test ModelCompare.constraint_set_to_bound(MOI.GreaterThan(3.0)) == (3.0, typemax(Float64))
        @test ModelCompare.constraint_set_to_bound(MOI.EqualTo(7.0)) == (7.0, 7.0)
        @test ModelCompare.constraint_set_to_bound(MOI.Interval(2.0, 8.0)) == (2.0, 8.0)
    end

    @testset "remove_quotes" begin
        @test ModelCompare.remove_quotes("hello") == "hello"
        @test ModelCompare.remove_quotes("\"quoted\"") == "quoted"
        @test ModelCompare.remove_quotes("no\"quotes\"here") == "noquoteshere"
    end

    @testset "printdiff — one_by_one=false branches" begin
        m1 = ModelCompare.readmodel(MODEL1_LP)
        m2 = ModelCompare.readmodel(MODEL2_LP)

        @testset "BoundsDiff one_by_one=false" begin
            bdiff = compare_bounds(m1, m2; tol = 0.0)
            io = IOBuffer()
            ModelCompare.printdiff(io, bdiff; one_by_one = false)
            output = String(take!(io))
            @test occursin("VARIABLE BOUNDS", output)
            @test occursin("MODEL 1:", output)
            @test occursin("MODEL 2:", output)
        end

        @testset "ObjectiveDiff one_by_one=false" begin
            odiff = compare_objective(m1, m2; tol = 0.0)
            io = IOBuffer()
            ModelCompare.printdiff(io, odiff; one_by_one = false)
            output = String(take!(io))
            @test occursin("OBJECTIVE", output)
            @test occursin("MODEL 1:", output)
            @test occursin("MODEL 2:", output)
        end

        @testset "ExpressionDiff one_by_one=false" begin
            attr1 = MOI.get(m1, MOI.ObjectiveFunctionType())
            attr2 = MOI.get(m2, MOI.ObjectiveFunctionType())
            obj1 = MOI.get(m1, MOI.ObjectiveFunction{attr1}())
            obj2 = MOI.get(m2, MOI.ObjectiveFunction{attr2}())
            ediff = compare_expressions(obj1, obj2, m1, m2; tol = 0.0)
            io = IOBuffer()
            ModelCompare.printdiff(io, ediff, "OBJECTIVE"; one_by_one = false)
            output = String(take!(io))
            @test occursin("MODEL 1:", output)
            @test occursin("MODEL 2:", output)
        end

        @testset "ExpressionDiff with constraint name" begin
            attr1 = MOI.get(m1, MOI.ObjectiveFunctionType())
            attr2 = MOI.get(m2, MOI.ObjectiveFunctionType())
            obj1 = MOI.get(m1, MOI.ObjectiveFunction{attr1}())
            obj2 = MOI.get(m2, MOI.ObjectiveFunction{attr2}())
            ediff = compare_expressions(obj1, obj2, m1, m2; tol = 0.0)
            io = IOBuffer()
            ModelCompare.printdiff(io, ediff, "my_constraint"; one_by_one = true)
            output = String(take!(io))
            @test occursin("CONSTRAINT: my_constraint", output)
        end

        @testset "ConstraintElementsDiff one_by_one=false" begin
            cdiff = compare_constraints(m1, m2; tol = 0.0)
            io = IOBuffer()
            ModelCompare.printdiff(io, cdiff; one_by_one = false)
            output = String(take!(io))
            @test occursin("CONSTRAINTS", output)
        end
    end

    @testset "printdiff — VariablesDiff identical (empty diffs)" begin
        m1 = ModelCompare.readmodel(MODEL1_LP)
        vdiff = compare_variables(m1, m1)
        io = IOBuffer()
        ModelCompare.printdiff(io, vdiff)
        output = String(take!(io))
        # When both only_one and only_two are empty, no header is printed
        @test !occursin("VARIABLE NAMES", output)
    end

    @testset "printdiff — ObjectiveDiff different senses" begin
        # Build a fake ObjectiveDiff with different senses
        ediff = ModelCompare.ExpressionDiff(String[], Dict{String,Tuple{Float64,Float64}}(), Dict{String,Float64}(), Dict{String,Float64}())
        odiff = ModelCompare.ObjectiveDiff((MOI.MAX_SENSE, MOI.MIN_SENSE), ediff)
        io = IOBuffer()
        ModelCompare.printdiff(io, odiff; one_by_one = true)
        output = String(take!(io))
        @test occursin("OBJECTIVE SENSES ARE DIFFERENT", output)
        @test occursin("MODEL 1:", output)
        @test occursin("MODEL 2:", output)
    end

    @testset "printdiff — ConstraintElementsDiff with first-only constraints" begin
        # Compare model2 vs model1 (reversed) so that model1-unique constraints appear in .first
        m1 = ModelCompare.readmodel(MODEL2_LP)
        m2 = ModelCompare.readmodel(MODEL1_LP)
        cdiff = compare_constraints(m1, m2; tol = 0.0)
        io = IOBuffer()
        ModelCompare.printdiff(io, cdiff; one_by_one = true)
        output = String(take!(io))
        @test occursin("MODEL 1:", output)
    end

    @testset "compare — string path overload" begin
        result = ModelCompare.compare(MODEL1_LP, MODEL2_LP; tol = 0.0)
        @test result isa NamedTuple
        @test haskey(result, :variables)
        @test haskey(result, :bounds)
        @test haskey(result, :objective)
        @test haskey(result, :constraints)
    end

    @testset "compare_models — verbose separate_files" begin
        mktempdir() do dir
            outfile = joinpath(dir, "compare.txt")
            compare_models(MODEL1_LP, MODEL2_LP;
                outfile = outfile, tol = 0.0, separate_files = true, verbose = true)
            @test isfile(joinpath(dir, "compare_variables.txt"))
            @test isfile(joinpath(dir, "compare_bounds.txt"))
            @test isfile(joinpath(dir, "compare_objective.txt"))
            @test isfile(joinpath(dir, "compare_constraints.txt"))
        end
    end

    @testset "parse_commandline" begin
        args = ["--file1", "a.lp", "--file2", "b.lp", "-t", "0.01", "-v", "--different-files", "-o", "out.txt"]
        parsed = ModelCompare.parse_commandline(args)
        @test parsed["file1"] == "a.lp"
        @test parsed["file2"] == "b.lp"
        @test parsed["tol"] == 0.01
        @test parsed["verbose"] == true
        @test parsed["different-files"] == true
        @test parsed["output"] == "out.txt"
    end

    @testset "parse_commandline — defaults" begin
        args = ["--file1", "a.lp", "--file2", "b.lp"]
        parsed = ModelCompare.parse_commandline(args)
        @test parsed["tol"] == 1e-3
        @test parsed["verbose"] == false
        @test parsed["different-files"] == false
        @test occursin("compare.txt", parsed["output"])
    end

    @testset "call_compare" begin
        mktempdir() do dir
            outfile = joinpath(dir, "result.txt")
            args = ["--file1", MODEL1_LP, "--file2", MODEL2_LP, "-o", outfile, "-t", "0.0"]
            result = ModelCompare.call_compare(args)
            @test result isa NamedTuple
            @test isfile(outfile)
        end
    end

    @testset "julia_main" begin
        mktempdir() do dir
            outfile = joinpath(dir, "result.txt")
            old_args = copy(ARGS)
            empty!(ARGS)
            append!(ARGS, ["--file1", MODEL1_LP, "--file2", MODEL2_LP, "-o", outfile, "-t", "0.0"])
            ret = ModelCompare.julia_main()
            @test ret == 0
            @test isfile(outfile)
            empty!(ARGS)
            append!(ARGS, old_args)
        end
    end

    @testset "variable_names and index_for_name" begin
        m = ModelCompare.readmodel(MODEL1_LP)
        names = collect(ModelCompare.variable_names(m))
        @test !isempty(names)
        @test "d" in names
        idx_map = ModelCompare.index_for_name(m)
        @test haskey(idx_map, "d")
    end

    @testset "constraint_names and ctr_index_for_name" begin
        m = ModelCompare.readmodel(MODEL1_LP)
        cnames = collect(ModelCompare.constraint_names(m))
        @test !isempty(cnames)
        ctr_map = ModelCompare.ctr_index_for_name(m)
        @test !isempty(ctr_map)
    end

end
