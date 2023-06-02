using ModelCompare

@time compare_models(
    "test/models/model1.mps",
    "test/models/model2.mps",
    outfile = "test/models/compare_mps.txt", 
    tol = 0.0
)

@time compare_models(
    "test/models/model1.lp",
    "test/models/model2.lp",
    outfile = "test/models/compare_lp.txt",
    tol = 0.0
)

@time compare_models(
    "test/models/modelbiglp1.mps",
    "test/models/modelbiglp2.mps",
    outfile = "test/models/comparebiglp_mps.txt", 
    tol = 0.0
)

@time compare_models(
    "test/models/modelbiglp1.lp",
    "test/models/modelbiglp2.lp",
    outfile = "test/models/comparebiglp_lp.txt", 
    tol = 0.0
)