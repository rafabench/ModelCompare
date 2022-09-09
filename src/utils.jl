function read_from_file(file1::String, file2::String)
    model1 = MOIF.Model(filename = file1)
    MOI.read_from_file(model1, file1)
    model2 = MOIF.Model(filename = file2)
    MOI.read_from_file(model2, file2)
    return model1,model2
end

function read_from_file_copy(file1::String, file2::String)
    model1 = MOIF.Model(filename = file1)
    MOI.read_from_file(model1, file1)
    model2 =MOIF.Model(filename = file2)
    return model1,model2
end

function remove_quotes(string::String)
    return replace(string, r"\"" => s"")
end

function print_header(openfile, string)
    write(openfile, "\n", "#"^80, "\n")
    write(openfile, string, "\n")
    write(openfile, "#"^80, "\n\n")
end
