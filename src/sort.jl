function sort_model(file1::String)

    src = readmodel(file1)
    file2 = file1*".sorted"
    dest = MOIF.Model(filename = file2)
    sorted_variable_1 = sort(collect(src.var_to_name), by=x->x[2])
    all_variables_1 = [[var[1],var[2]] for var in sorted_variable_1]
    moi_vi_indices = hcat(all_variables_1...)[1,:]
    indices = getfield.(moi_vi_indices,:value)
    var1_to_var2 = MOIU.CleverDicts.CleverDict{MOI.VariableIndex,MOI.VariableIndex}()
    n_vars = length(indices)
    for (idx,var) in enumerate(moi_vi_indices)
        var1_to_var2[var] = MOI.VariableIndex(idx)
    end

    sorted_cons_1 = sort(collect(src.con_to_name), by=x->x[2])
    all_cons_1 = [MOI.get(src,MOI.ConstraintFunction(),con[1]) for con in sorted_cons_1]
    sets_types = unique(typeof.(MOI.get.(src, MOI.ConstraintSet(), first.(sorted_cons_1))))
    
    names = last.(sorted_cons_1)
    con_idxs = first.(sorted_cons_1)
    con1_to_con2 = MOIU.DoubleDicts.IndexDoubleDict()
    con1_to_con2_idxs_vals = getfield.(first.(sorted_cons_1),:value)
    con1_to_con2_idxs_vals_set = hcat(con1_to_con2_idxs_vals,typeof.(MOI.get.(src, MOI.ConstraintSet(), first.(sorted_cons_1))))
    con1_to_con2_idxs = first.(sorted_cons_1)

    names_sets = Dict()
    for sets_type in sets_types
        for (ci,name) in sorted_cons_1
            curr_set_type = typeof(MOI.get(src, MOI.ConstraintSet(), ci))
            if curr_set_type == sets_type
                if !haskey(names_sets,sets_type)
                    names_sets[sets_type] = [name]
                else
                    push!(names_sets[sets_type],name)
                end
            end
        end
    end


    for (idx,con) in enumerate(sorted_cons_1)
        func = typeof(con[1])
        con1_to_con2[func(idx)] = con[1]
    end

    MOI.empty!(dest)
    idx_map_model1_to_2 = MOIU.IndexMap(var1_to_var2,con1_to_con2)
    vis_src = MOI.get(src, MOI.ListOfVariableIndices())

    x = MOI.add_variables(dest, n_vars)
    
    # Copy variable attributes
    MOIU.pass_attributes(dest, src, idx_map_model1_to_2, vis_src)
    
    # Copy model attributes
    F = MOI.get(src, MOI.ObjectiveFunctionType())

    MOIU._pass_attribute(dest, src, idx_map_model1_to_2, MOI.ObjectiveSense())
    MOIU._pass_attribute(dest, src, idx_map_model1_to_2, MOI.ObjectiveFunction{F}())

    objective = MOI.get(dest,MOI.ObjectiveFunction{F}())
    
    terms_in_obj = [term.variable.value for term in objective.terms]
    permvec = sortperm(terms_in_obj)
    objective2 = F(objective.terms[permvec],objective.constant)
    MOI.set(dest,MOI.ObjectiveFunction{F}(), objective2)

    sense1 = MOI.get(src,MOI.ObjectiveSense())
    MOI.set(dest,MOI.ObjectiveSense(),sense1)
    
    T = Float64
    F = MOI.VariableIndex
    Sets = [MOI.LessThan{T},MOI.EqualTo{T},MOI.GreaterThan{T},MOI.Interval{T},MOI.ZeroOne,MOI.Integer]
    var_to_bound = Dict(MOI.VariableIndex(i) => [] for i in indices)
    for S in Sets
        list = MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
        for ci in list
            f = MOI.get(src, MOI.ConstraintFunction(), ci)
            s = MOI.get(src, MOI.ConstraintSet(), ci)
            push!(var_to_bound[f],s)
        end
    end
    for i in indices
        f = MOI.VariableIndex(i)
        for s in var_to_bound[f]
            MOI.add_constraint(dest, MOIU.map_indices(idx_map_model1_to_2, f), s)
        end
    end

    for (i,ci) in enumerate(con1_to_con2_idxs)
        f = MOI.get(src, MOI.ConstraintFunction(), ci)
        s = MOI.get(src, MOI.ConstraintSet(), ci)
        set_type = typeof(s)
        MOI.add_constraint(dest, MOIU.map_indices(idx_map_model1_to_2, f), s)
        MOI.set(dest, MOI.ConstraintName(), ci, names_sets[set_type][con1_to_con2_idxs_vals[i]])
    end
    MOIU.final_touch(dest, idx_map_model1_to_2)

    write_to_file_m(dest, file2)
end