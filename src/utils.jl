function readmodel(fname)
    m = MOIF.Model(filename = fname)
    MOI.read_from_file(m, fname)
    return m
end

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

"""
    partition(A, B)

Partition two collections into disjoint collections
containing their intersection and the elements unique to each of them:

    partition(A, B) = (A ∩ B, A \\ B, B \\ A)
"""
function partition(xs, ys)
    inter = intersect(xs, ys)
    return inter, setdiff(xs, inter), setdiff(ys, inter)
end
