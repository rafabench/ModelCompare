struct ObjectiveDiff
    sense::Tuple{MOI.OptimizationSense, MOI.OptimizationSense}
    expression::ExpressionDiff
end

function compare_objective(model1::MOI.ModelLike, model2::MOI.ModelLike; tol::Float64)
    sense1 = MOI.get(model1, MOI.ObjectiveSense())
    sense2 = MOI.get(model2, MOI.ObjectiveSense())
    attr1 = MOI.get(model1, MOI.ObjectiveFunctionType())
    attr2 = MOI.get(model2, MOI.ObjectiveFunctionType())
    objective1 = MOI.get(model1,MOI.ObjectiveFunction{attr1}())
    objective2 = MOI.get(model2,MOI.ObjectiveFunction{attr2}())
    expression_diff = compare_expressions(
        objective1, 
        objective2,
            model1,
            model2;
            tol = tol
        )
    return ObjectiveDiff((sense1, sense2), expression_diff)
end

function printdiff(io::IO, odiff::ObjectiveDiff; one_by_one::Bool)
    sense1, sense2 = odiff.sense
    expression_diff = odiff.expression
    print_header(io, "OBJECTIVE")
    if sense1 != sense2
        write(io, "\tOBJECTIVE SENSES ARE DIFFERENT:","\n")
        write(io, "\t\tMODEL 1: ",sense1,"\n")
        write(io, "\t\tMODEL 2: ",sense2,"\n")
    end
    printdiff(io, expression_diff, "OBJECTIVE"; one_by_one = one_by_one)
end