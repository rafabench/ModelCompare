## ModelComparator

The purpose of this project is to compare two optimization models in two different files.

### Running

If you have 2 files like `model1.lp` and `model2.lp` in the folder `test`. You can compare them by running:

```julia
compare_models(
    file1 = "test/models/model1.lp",
    file2 = "test/models/model2.lp",
    outfile = "test/models/compare_lp.txt", 
    tol = 1e-3
)
```

### Analyzing the results

The section `VARIABLE NAMES` says which variable belongs to each model.

```
	MODEL 1
		w
		x
		z_a
    MODEL 2
		p
		t
		z_10_
		z_6_
		z_7_
		z_8_
		z_9_
		z_a_1_
		z_a_2_
```

The variables `w,x,z_a` belongs only to the first model and `p,t,z_10_,z_6_,z_7_,z_8_,z_9_,z_a_1_,z_a_2_` belongs only to the first model. If both models have the same variables, it doesn't show on the results.

In the objective section, it shows which coefficient are different.

```
	SAME VARIABLES
	y_1_
		 MODEL 1 => 3.0
		 MODEL 2 => 5.0
	y_2_
		 MODEL 1 => 3.0
		 MODEL 2 => 5.0
	d
		 MODEL 1 => 5.0
		 MODEL 2 => 1.0
	DIFFERENT VARIABLES:
	MODEL 1:
		w => 0.5
		x => 2.0
		z_a => 1.0
	MODEL 2:
		z_8_ => 1.0
		z_a_1_ => 1.0
		z_7_ => 1.0
		z_a_2_ => 1.0
		z_9_ => 1.0
		z_6_ => 1.0
		z_10_ => 1.0
		p => 3.0
```

The variable `y_1_` has a coefficient 3.0 multiplying it in the model1 and 5.0 in the model 2.

In the bounds section, it shows which bounds are different.

```
DIFFERENT VARIABLES:
	MODEL 1:
		w => [30.0,Inf)
		x => [0.0,Inf)
		z_a => [25.0,25.0]
```

The variable `w` has bounds $[30.0,\infty)$. The `z` variable is fixed in `25`.

In the constraint section it shows the coefficients of the variables that are different and if the constraint bounds are different.

**You can only compare constraints with the same name, otherwise, it will be ignored.**

```
CONSTRAINT: c1
	DIFFERENT VARIABLES:
	MODEL 1:
		z_4_ => 2.0
		z_2_ => 2.0
		z_5_ => 2.0
		z_3_ => 2.0
		z_1_ => 2.0
		z_a => 1.0
	MODEL 2:
		z_a_1_ => 2.0
		z_a_2_ => 1.0
	SETS
		MODEL 1: MathOptInterface.GreaterThan{Float64}(3.0)
		MODEL 2: MathOptInterface.EqualTo{Float64}(3.0)


CONSTRAINT: z_con
	DIFFERENT VARIABLES:
	MODEL 2:
		z_8_ => 1.0
		z_7_ => 1.0
		z_9_ => 1.0
		z_6_ => 1.0
		z_10_ => 1.0
```

On the constraint `c1`. In the first model, it has the variables `z_1_,z_2_,z_3_,z_4_,z_5_,z_a_` on the constraint `c1`  and the second model doesn't have this variables in this constraint. Also, `z_1_` has a coefficient of 2 on the constraint `c1` and so on.

In the first model, the `c1` constraint has a bound of `Greater than 3` and on the second model `Equal to 3`.