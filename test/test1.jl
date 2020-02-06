using ModelComparator

@time compare_models(file1 = "model1.mps",file2 = "model2.mps", get_bounds = true, outfile = "compare.txt")
@time compare_models(file1 = "modelbiglp1.mps",file2 = "modelbiglp2.mps", get_bounds = true, outfile = "comparebiglp.txt")