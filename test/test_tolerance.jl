using ModelComparator

@time compare_models(file1 = "model_tol_1.mps",file2 = "model_tol_2.mps", get_bounds = true, outfile = "compare_tol.txt", tol = 1e-3)
@time compare_models(file1 = "modelbiglp_tol_1.mps",file2 = "modelbiglp_tol_2.mps", get_bounds = true, outfile = "comparebiglp_tol.txt", tol = 1e-3)