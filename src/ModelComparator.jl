module ModelComparator

export read_from_file, compare_variables, compare_expressions, compare_objective, compare_bounds, compare_constraints, compare_models

using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

@include("compare.jl")

end 
