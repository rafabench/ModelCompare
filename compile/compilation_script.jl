using ModelComparator

current = pwd()
cd(@__DIR__)
compare_models(
    file1 = "./models/model1.mps",
    file2 = "./models/model2.mps",
    outfile = "./models/compare_mps.txt", 
    tol = 0
)
cd(current)