using ModelCompare

@time compare_models(
    file1 = "test/models/model1.mps",
    file2 = "test/models/model2.mps",
    outfile = "test/models/compare_mps.txt", 
    tol = 0
)

@time compare_models(
    file1 = "test/models/model1.lp",
    file2 = "test/models/model2.lp",
    outfile = "test/models/compare_lp.txt",
    tol = 0
)

@time compare_models(
    file1 = "test/models/modelbiglp1.mps",
    file2 = "test/models/modelbiglp2.mps",
    outfile = "test/models/comparebiglp_mps.txt", 
    tol = 0
)

@time compare_models(
    file1 = "test/models/modelbiglp1.lp",
    file2 = "test/models/modelbiglp2.lp",
    outfile = "test/models/comparebiglp_lp.txt", 
    tol = 0
)