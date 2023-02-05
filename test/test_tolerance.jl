using ModelCompare

for tol in [1e-3, 1e-4]

    @time compare_models(
        file1 = "test/models/model1.mps",
        file2 = "test/models/model2.mps",
        outfile = "test/models/compare_mps_tol$tol.txt", 
        tol = tol
    )

    @time compare_models(
        file1 = "test/models/model1.lp",
        file2 = "test/models/model2.lp",
        outfile = "test/models/compare_lp_tol$tol.txt", 
        tol = tol
    )

    @time compare_models(
        file1 = "test/models/modelbiglp1.mps",
        file2 = "test/models/modelbiglp2.mps",
        outfile = "test/models/comparebiglp_mps_tol$tol.txt", 
        tol = tol
    )

    @time compare_models(
        file1 = "test/models/modelbiglp1.lp",
        file2 = "test/models/modelbiglp2.lp",
        outfile = "test/models/comparebiglp_lp_tol$tol.txt", 
        tol = tol
    )
end