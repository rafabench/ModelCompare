function read_from_file(file1::String, file2::String)
    model1 = MOI.FileFormats.Model(filename = file1)
    MOI.read_from_file(model1, file1)
    model2 = MOI.FileFormats.Model(filename = file2)
    MOI.read_from_file(model2, file2)
    return model1,model2
end

function remove_quotes(string::String)
    return replace(string, r"\"" => s"")
end