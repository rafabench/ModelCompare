using ModelComparator

@time compare_models(file1 = "models/model_tol_1.mps",file2 = "models/model_tol_2.mps", get_bounds = true, outfile = "models/compare_tol_e-3.txt", tol = 1e-3)
@time compare_models(file1 = "models/modelbiglp_tol_1.mps",file2 = "models/modelbiglp_tol_2.mps", get_bounds = true, outfile = "models/comparebiglp_tol_e-3.txt", tol = 1e-3)

@time compare_models(file1 = "models/model_tol_1.mps",file2 = "models/model_tol_2.mps", get_bounds = true, outfile = "models/compare_tol_e-4.txt", tol = 1e-4)
@time compare_models(file1 = "models/modelbiglp_tol_1.mps",file2 = "models/modelbiglp_tol_2.mps", get_bounds = true, outfile = "models/comparebiglp_tol_e-4.txt", tol = 1e-4)