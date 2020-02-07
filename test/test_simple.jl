using ModelComparator

@time compare_models(file1 = "models/model1.mps",file2 = "models/model2.mps", get_bounds = true, outfile = "models/compare.txt", tol = 0)
@time compare_models(file1 = "models/modelbiglp1.mps",file2 = "models/modelbiglp2.mps", get_bounds = true, outfile = "models/comparebiglp.txt", tol = 0)