function detach_model(file::String)
    
    file_name = first(splitext(file))

    objective_path = file_name*"_OBJ.txt"
    constraint_path = file_name*"_CONSTR.txt"
    variable_path = file_name*"_VAR.txt"
    touch(objective_path)
    touch(constraint_path)
    touch(variable_path)

    open(file,"r") do f
        lines = readlines(f)
        line_i = 1
        open(objective_path, "w") do io
            for line in lines
                if startswith(line,"Subject To") || startswith(line, "SUBJECT TO")
                    break
                end
                println(io, line)
                line_i += 1
            end
        end
        open(constraint_path, "w") do io
            for line in lines[line_i:end]
                if startswith(line,"Binary") || startswith(line, "Binaries")
                    break
                end
                println(io, line)
                line_i += 1
            end
        end
        open(variable_path, "w") do io
            for line in lines[line_i:end]
                println(io, line)
            end
        end
    end
end