struct ConstraintNamesDiff
    in_both  :: Vector{String}
    only_one :: Vector{String}
    only_two :: Vector{String}
end

# Compare expression of constraints and objective function
# Then, compare bounds of constraints
struct ConstraintElementsDiff
    equal::Vector{String}
    both::Dict{String, Tuple{ExpressionDiff, Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}}}
    first::Dict{String, Tuple{Dict{String, Float64}, Tuple{Float64, Float64}}}
    second::Dict{String, Tuple{Dict{String, Float64}, Tuple{Float64, Float64}}}
end

function compare_constraints(model1::MOI.ModelLike, model2::MOI.ModelLike; tol::Float64)
    condiff = ConstraintNamesDiff(partition(constraint_names(model1), constraint_names(model2))...)
    ctrindices1 = ctr_index_for_name(model1)
    ctrindices2 = ctr_index_for_name(model2)
    con_first = Dict(name => 
                    (
                        Dict(model1.var_to_name[var.variable] => var.coefficient
                        for var in MOI.get(model1, MOI.ConstraintFunction(), ctrindices1[name]).terms),
                        constraint_set_to_bound(MOI.get(model1, MOI.ConstraintSet(), ctrindices1[name])))
                    for name in condiff.only_one)
    con_second = Dict(name => 
                    (
                        Dict(model2.var_to_name[var.variable] => var.coefficient
                        for var in MOI.get(model2, MOI.ConstraintFunction(), ctrindices2[name]).terms),
                        constraint_set_to_bound(MOI.get(model2, MOI.ConstraintSet(), ctrindices2[name])))
                    for name in condiff.only_two)

    p = ProgressMeter.Progress(length(condiff.in_both), "Comparing constraints...")
    con_both = Dict{String, Tuple{ExpressionDiff, Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}}}()
    equal = String[]

    for name in condiff.in_both
        f1 = MOI.get(model1, MOI.ConstraintSet(), ctrindices1[name])
        f2 = MOI.get(model2, MOI.ConstraintSet(), ctrindices2[name])
        set1 = constraint_set_to_bound(f1)
        set2 = constraint_set_to_bound(f2)
        
        expression_diff = compare_expressions(
                MOI.get(model1, MOI.ConstraintFunction(), ctrindices1[name]), 
                MOI.get(model2, MOI.ConstraintFunction(), ctrindices2[name]),
                model1,
                model2;
                tol = tol
                )
        if all(isapprox.(set1, set2; atol = tol)) && 
            isempty(expression_diff.both) &&
            isempty(expression_diff.first) &&
            isempty(expression_diff.second)
            push!(equal, name)
        else
            con_both[name] = (expression_diff, (set1, set2))
        end
        next!(p)
    end

    return ConstraintElementsDiff(sort!(equal), con_both, con_first, con_second)
end

function printdiff(io::IO, con_diff::ConstraintElementsDiff; one_by_one::Bool)
    equal, both, only1, only2 = con_diff.equal, con_diff.both, con_diff.first, con_diff.second

    if !isempty(only1) || !isempty(only2) || !isempty(both)
        print_header(io, "CONSTRAINTS")
    end

    if !isempty(both)
        write(io, "SAME CONSTRAINTS:\n\n")
        for (name, (expression_diff, (set1, set2))) in both
            printdiff(io, expression_diff, name; one_by_one = one_by_one)
            write(io, "\tSETS:\n")
            write(io, "\t\t", "MODEL 1 => ", string(set1) ,"\n")
            write(io, "\t\t", "MODEL 2 => ", string(set2) ,"\n\n")
        end
    end

    if !isempty(only1) || !isempty(only2)
        write(io, "\tDIFFERENT CONSTRAINTS:\n")
    end

    if !isempty(only1)
        write(io, "\t", "MODEL 1:", "\n")
        for (name, (coefs, set)) in only1
            write(io, "\t\t", name, ":\n")
            write(io, "\t\t\tSET:", string(set) ,"\n")
            for (var, coef) in coefs
                write(io, "\t\t\t", var, " => ", string(coef) ,"\n")
            end
            write(io, "\n")
        end
    end

    if !isempty(only2)
        write(io, "\t", "MODEL 2:", "\n")
        for (name, (coefs, set)) in only2
            write(io, "\t\t", name, ":\n")
            write(io, "\t\t\t SET:", string(set) ,"\n")
            for (var, coef) in coefs
                write(io, "\t\t\t", var, " => ", string(coef) ,"\n")
            end
        end
    end
end

function constraint_names(m::MOI.ModelLike)
    # TODO: Can we extract this without snooping into the model's private fields?
    # That is, only with MOI.get?
    return values(m.con_to_name)
end

function ctr_index_for_name(m::MOI.ModelLike)
    return Dict(v => k for (k, v) in m.con_to_name)
end

constraint_set_to_bound(constraint_set::MOI.LessThan{T}) where {T} = (typemin(T), constraint_set.upper)
constraint_set_to_bound(constraint_set::MOI.GreaterThan{T}) where {T} = (constraint_set.lower, typemax(T))
constraint_set_to_bound(constraint_set::MOI.Interval{T}) where {T} = (constraint_set.lower, constraint_set.upper)
constraint_set_to_bound(constraint_set::MOI.EqualTo{T}) where {T} = (constraint_set.value, constraint_set.value)