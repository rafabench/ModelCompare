module ModelCompare

export read_from_file, compare_variables, compare_expressions, compare_objective, compare_bounds, compare_constraints, compare_models

using MathOptInterface
using ArgParse
using ProgressMeter
const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIF = MOI.FileFormats

include("utils.jl")
include("variables.jl")
include("bounds.jl")
include("expression.jl")
include("objective.jl")
include("constraints.jl")
include("compare.jl")
include("args.jl")
include("lp_write_moi.jl")
include("sort.jl")
include("detach.jl")

end 
