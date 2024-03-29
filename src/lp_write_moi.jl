const _START_REG = r"^([\.0-9eE])"
const _NAME_REG = r"([^a-zA-Z0-9\!\"\#\$\%\&\(\)\/\,\.\;\?\@\_\`\'\{\}\|\~])"

function _write_function(
    io::IO,
    ::MOIF.LP.Model,
    func::MOI.VariableIndex,
    variable_names::Dict{MOI.VariableIndex,String};
    kwargs...,
)
    print(io, variable_names[func])
    return
end

function _write_function(
    io::IO,
    ::MOIF.LP.Model,
    func::MOI.ScalarAffineFunction{Float64},
    variable_names::Dict{MOI.VariableIndex,String};
    kwargs...,
)
    is_first_item = true
    if !(func.constant ≈ 0.0)
        MOIF.LP._print_shortest(io, func.constant)
        is_first_item = false
    end
    for (idx,term) in enumerate(func.terms)
        if !(term.coefficient ≈ 0.0)
            if is_first_item
                MOIF.LP._print_shortest(io, term.coefficient)
                is_first_item = false
            else
                print(io, term.coefficient < 0 ? " - " : " + ")
                MOIF.LP._print_shortest(io, abs(term.coefficient))
            end
            print(io, " ", variable_names[term.variable])
            if idx%3 == 0 && idx != length(func.terms)
                print(io,"\n")
            end
        end
    end
    return
end

function _write_function(
    io::IO,
    ::MOIF.LP.Model,
    func::MOI.ScalarQuadraticFunction{Float64},
    variable_names::Dict{MOI.VariableIndex,String};
    print_half::Bool = true,
    kwargs...,
)
    is_first_item = true
    if !(func.constant ≈ 0.0)
        MOIF.LP._print_shortest(io, func.constant)
        is_first_item = false
    end
    for term in func.affine_terms
        if !(term.coefficient ≈ 0.0)
            if is_first_item
                MOIF.LP._print_shortest(io, term.coefficient)
                is_first_item = false
            else
                print(io, term.coefficient < 0 ? " - " : " + ")
                MOIF.LP._print_shortest(io, abs(term.coefficient))
            end
            print(io, " ", variable_names[term.variable])
        end
    end
    if length(func.quadratic_terms) > 0
        if is_first_item
            print(io, "[ ")
        else
            print(io, " + [ ")
        end
        is_first_item = true
        for term in func.quadratic_terms
            coefficient = term.coefficient
            if !print_half && term.variable_1 == term.variable_2
                coefficient /= 2
            end
            if is_first_item
                MOIF.LP._print_shortest(io, coefficient)
                is_first_item = false
            else
                print(io, coefficient < 0 ? " - " : " + ")
                MOIF.LP._print_shortest(io, abs(coefficient))
            end
            print(io, " ", variable_names[term.variable_1])
            if term.variable_1 == term.variable_2
                print(io, " ^ 2")
            else
                print(io, " * ", variable_names[term.variable_2])
            end
        end
        if print_half
            print(io, " ]/2")
        else
            print(io, " ]")
        end
    end
    return
end

function _write_constraint_suffix(io::IO, set::MOI.LessThan)
    print(io, " <= ")
    MOIF.LP._print_shortest(io, set.upper)
    println(io)
    return
end

function _write_constraint_suffix(io::IO, set::MOI.GreaterThan)
    print(io, " >= ")
    MOIF.LP._print_shortest(io, set.lower)
    println(io)
    return
end

function _write_constraint_suffix(io::IO, set::MOI.EqualTo)
    print(io, " = ")
    MOIF.LP._print_shortest(io, set.value)
    println(io)
    return
end

function _write_constraint_suffix(io::IO, set::MOI.Interval)
    print(io, " <= ")
    MOIF.LP._print_shortest(io, set.upper)
    println(io)
    return
end

function _write_constraint_prefix(io::IO, set::MOI.Interval)
    MOIF.LP._print_shortest(io, set.lower)
    print(io, " <= ")
    return
end

_write_constraint_prefix(::IO, ::Any) = nothing

function _write_constraint(
    io::IO,
    model::MOIF.LP.Model,
    index::MOI.ConstraintIndex,
    variable_names::Dict{MOI.VariableIndex,String};
    write_name::Bool = true,
)
    func = MOI.get(model, MOI.ConstraintFunction(), index)
    set = MOI.get(model, MOI.ConstraintSet(), index)
    if write_name
        print(io, MOI.get(model, MOI.ConstraintName(), index), ": ")
    end
    _write_constraint_prefix(io, set)
    _write_function(io, model, func, variable_names; print_half = false)
    _write_constraint_suffix(io, set)
    return
end

const _SCALAR_SETS = (
    MOI.LessThan{Float64},
    MOI.GreaterThan{Float64},
    MOI.EqualTo{Float64},
    MOI.Interval{Float64},
)

function _write_sense(io::IO, model::MOIF.LP.Model)
    if MOI.get(model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        println(io, "MAXIMIZE")
    else
        println(io, "MINIMIZE")
    end
    return
end

function _write_objective(
    io::IO,
    model::MOIF.LP.Model,
    variable_names::Dict{MOI.VariableIndex,String},
)
    print(io, "OBJECTIVE: ")
    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())
    _write_function(io, model, f, variable_names)
    println(io)
    return
end

function _write_integrality(
    io::IO,
    model::MOIF.LP.Model,
    key::String,
    ::Type{S},
    variable_names::Dict{MOI.VariableIndex,String},
) where {S}
    indices = MOI.get(model, MOI.ListOfConstraintIndices{MOI.VariableIndex,S}())
    if length(indices) == 0
        return
    end
    println(io, key)
    for index in indices
        f = MOI.get(model, MOI.ConstraintFunction(), index)
        _write_function(io, model, f, variable_names)
        println(io)
    end
    return
end

function _write_constraints(io, model, variable_names)
    cons = first.(sort(collect(model.con_to_name), by=x->x[2]))
    for index in cons
        _write_constraint(io, model, index, variable_names; write_name = true)
    end
    return
end

function _write_bounds(io, model, S, variable_names, free_variables)
    F = MOI.VariableIndex
    for index in MOI.get(model, MOI.ListOfConstraintIndices{F,S}())
        delete!(free_variables, MOI.VariableIndex(index.value))
        _write_constraint(io, model, index, variable_names; write_name = false)
    end
    return
end

function _write_sos_constraints(io, model, variable_names)
    T, F = Float64, MOI.VectorOfVariables
    sos1_indices = MOI.get(model, MOI.ListOfConstraintIndices{F,MOI.SOS1{T}}())
    sos2_indices = MOI.get(model, MOI.ListOfConstraintIndices{F,MOI.SOS2{T}}())
    if length(sos1_indices) + length(sos2_indices) == 0
        return
    end
    println(io, "SOS")
    for index in sos1_indices
        _write_constraint(io, model, index, variable_names)
    end
    for index in sos2_indices
        _write_constraint(io, model, index, variable_names)
    end
    return
end

_to_string(::Type{MOI.SOS1{Float64}}) = "S1::"
_to_string(::Type{MOI.SOS2{Float64}}) = "S2::"

function _write_constraint(
    io::IO,
    model::MOIF.LP.Model,
    index::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
    variable_names::Dict{MOI.VariableIndex,String},
) where {S<:Union{MOI.SOS1{Float64},MOI.SOS2{Float64}}}
    f = MOI.get(model, MOI.ConstraintFunction(), index)
    s = MOI.get(model, MOI.ConstraintSet(), index)
    name = MOI.get(model, MOI.ConstraintName(), index)
    if name !== nothing && !isempty(name)
        print(io, name, ": ")
    end
    print(io, _to_string(S))
    for (w, x) in zip(s.weights, f.variables)
        print(io, " ", variable_names[x], ":", w)
    end
    println(io)
    return
end

"""
    Base.write(io::IO, model::FileFormats.LP.Model)
Write `model` to `io` in the LP file format.
"""
function my_write(io::IO, model::MOIF.LP.Model)
    options = MOIF.LP.get_options(model)
    MOIF.create_unique_names(
        model,
        warn = options.warn,
        replacements = [
            s -> match(_START_REG, s) !== nothing ? "_" * s : s,
            s -> replace(s, _NAME_REG => "_"),
            s -> s[1:min(length(s), options.maximum_length)],
        ],
    )
    variable_names = Dict{MOI.VariableIndex,String}(
        index => MOI.get(model, MOI.VariableName(), index) for
        index in MOI.get(model, MOI.ListOfVariableIndices())
    )
    free_variables = Set(keys(variable_names))
    _write_sense(io, model)
    _write_objective(io, model, variable_names)
    println(io, "\nSUBJECT TO:")

    _write_constraints(io, model, variable_names)

    println(io, "\nBOUNDS:")
    for S in _SCALAR_SETS
        _write_bounds(io, model, S, variable_names, free_variables)
    end
    # If a variable is binary, it should not be listed as `free` in the bounds
    # section.
    attr = MOI.ListOfConstraintIndices{MOI.VariableIndex,MOI.ZeroOne}()
    for index in MOI.get(model, attr)
        delete!(free_variables, MOI.VariableIndex(index.value))
    end
    # By default, variables have bounds of [0, ∞), so we need to explicitly
    # declare variables as free.
    for variable in sort(collect(free_variables), by = x -> x.value)
        println(io, variable_names[variable], " free")
    end
    _write_integrality(io, model, "General", MOI.Integer, variable_names)
    _write_integrality(io, model, "Binary", MOI.ZeroOne, variable_names)
    _write_sos_constraints(io, model, variable_names)
    println(io, "End")
    return
end

function write_to_file_m(model::MOIF.LP.Model, filename::String)
    MOIF.compressed_open(filename, "w", MOIF.AutomaticCompression()) do io
        return my_write(io, model)
    end
end