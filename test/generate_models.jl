# test/generate_models.jl
#
# Generates all test model files in test/models/.
# Run with: julia --project=. test/generate_models.jl

using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIF = MOI.FileFormats
using Random

const MODELS_DIR = joinpath(@__DIR__, "models")
mkpath(MODELS_DIR)

# ── Helpers ──────────────────────────────────────────────────────────────────

function write_model_to_file(model::MOI.ModelLike, filename::String)
    filepath = joinpath(MODELS_DIR, filename)
    dest = MOIF.Model(filename = filepath)
    MOI.copy_to(dest, model)
    MOI.write_to_file(dest, filepath)
    println("  wrote $filename")
end

function add_var!(model, name)
    v = MOI.add_variable(model)
    MOI.set(model, MOI.VariableName(), v, name)
    return v
end

function add_constraint!(model, terms, set, name)
    func = MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(c, v) for (c, v) in terms], 0.0)
    ci = MOI.add_constraint(model, func, set)
    MOI.set(model, MOI.ConstraintName(), ci, name)
    return ci
end

# ── Small Model 1 ───────────────────────────────────────────────────────────
#
# Variables: x, y_1_, y_2_, z_1_..z_5_, z_a, w, d(integer)
# Objective: maximize 2x + 3y_1_ + z_a + z_1_ + z_2_ + z_4_ + z_5_ + 5d
# Constraints:
#   y_con:  y_1_ + y_2_ >= 5
#   c1:     z_a + 2z_1_ + 2z_2_ + 2z_3_ + 2z_4_ + 2z_5_ >= 3
#   z_con:  y_1_ + y_2_ + z_1_ + z_2_ + z_3_ + z_4_ + z_5_ >= 5
# Bounds: z_i in [0,1], w >= 30, x >= 0, y_1_ >= 1, y_2_ >= 2, z_a = 25, d >= 0

function build_model1()
    model = MOIU.Model{Float64}()

    x   = add_var!(model, "x")
    y1  = add_var!(model, "y_1_")
    y2  = add_var!(model, "y_2_")
    z1  = add_var!(model, "z_1_")
    z2  = add_var!(model, "z_2_")
    z3  = add_var!(model, "z_3_")
    z4  = add_var!(model, "z_4_")
    z5  = add_var!(model, "z_5_")
    za  = add_var!(model, "z_a")
    w   = add_var!(model, "w")
    d   = add_var!(model, "d")

    # Objective
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        MOI.ScalarAffineFunction([
            MOI.ScalarAffineTerm(2.0, x),
            MOI.ScalarAffineTerm(3.0, y1),
            MOI.ScalarAffineTerm(1.0, za),
            MOI.ScalarAffineTerm(1.0, z1),
            MOI.ScalarAffineTerm(1.0, z2),
            MOI.ScalarAffineTerm(1.0, z4),
            MOI.ScalarAffineTerm(1.0, z5),
            MOI.ScalarAffineTerm(5.0, d),
        ], 0.0))

    # Constraints
    add_constraint!(model, [(1.0, y2), (1.0, y1)], MOI.GreaterThan(5.0), "y_con")
    add_constraint!(model,
        [(1.0, za), (2.0, z3), (2.0, z2), (2.0, z1), (2.0, z4), (2.0, z5)],
        MOI.GreaterThan(3.0), "c1")
    add_constraint!(model,
        [(1.0, y1), (1.0, y2), (1.0, z1), (1.0, z2), (1.0, z3), (1.0, z4), (1.0, z5)],
        MOI.GreaterThan(5.0), "z_con")

    # Bounds
    for z in [z1, z2, z3, z4, z5]
        MOI.add_constraint(model, z, MOI.GreaterThan(0.0))
        MOI.add_constraint(model, z, MOI.LessThan(1.0))
    end
    MOI.add_constraint(model, w, MOI.GreaterThan(30.0))
    MOI.add_constraint(model, x, MOI.GreaterThan(0.0))
    MOI.add_constraint(model, y1, MOI.GreaterThan(1.0))
    MOI.add_constraint(model, y2, MOI.GreaterThan(2.0))
    MOI.add_constraint(model, za, MOI.EqualTo(25.0))
    MOI.add_constraint(model, d, MOI.GreaterThan(0.0))

    # Integrality
    MOI.add_constraint(model, d, MOI.Integer())

    return model
end

# ── Small Model 2 ───────────────────────────────────────────────────────────
#
# Variables: y_1_, y_2_, z_1_..z_10_, z_a_1_, z_a_2_, p, d(integer), t
# Objective: maximize 5y_1_ + 5y_2_ + z_1_..z_10_ + z_a_1_ + z_a_2_ + 3p + d
# Constraints:
#   y_con:  y_1_ + y_2_ >= 5
#   zcon:   3p + z_a_1_ + z_a_2_ >= 7
#   z_con:  y_1_ + y_2_ + z_1_..z_10_ >= 5
#   c1:     2z_a_1_ + z_a_2_ = 3
# Bounds: z_i in [0,1], y_1_ >= 1, y_2_ >= 2, p = 30, d free, t free
# Binary: z_a_1_, z_a_2_

function build_model2()
    model = MOIU.Model{Float64}()

    y1   = add_var!(model, "y_1_")
    y2   = add_var!(model, "y_2_")
    zvars = [add_var!(model, "z_$(i)_") for i in 1:10]
    za1  = add_var!(model, "z_a_1_")
    za2  = add_var!(model, "z_a_2_")
    p    = add_var!(model, "p")
    d    = add_var!(model, "d")
    t    = add_var!(model, "t")

    # Objective
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    obj_terms = [
        MOI.ScalarAffineTerm(5.0, y1),
        MOI.ScalarAffineTerm(5.0, y2),
        [MOI.ScalarAffineTerm(1.0, z) for z in zvars]...,
        MOI.ScalarAffineTerm(1.0, za1),
        MOI.ScalarAffineTerm(1.0, za2),
        MOI.ScalarAffineTerm(3.0, p),
        MOI.ScalarAffineTerm(1.0, d),
    ]
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        MOI.ScalarAffineFunction(obj_terms, 0.0))

    # Constraints
    add_constraint!(model, [(1.0, y1), (1.0, y2)], MOI.GreaterThan(5.0), "y_con")
    add_constraint!(model, [(3.0, p), (1.0, za1), (1.0, za2)], MOI.GreaterThan(7.0), "zcon")
    add_constraint!(model,
        [(1.0, y1), (1.0, y2), [(1.0, z) for z in zvars]...],
        MOI.GreaterThan(5.0), "z_con")
    add_constraint!(model, [(2.0, za1), (1.0, za2)], MOI.EqualTo(3.0), "c1")

    # Bounds
    for z in zvars
        MOI.add_constraint(model, z, MOI.GreaterThan(0.0))
        MOI.add_constraint(model, z, MOI.LessThan(1.0))
    end
    MOI.add_constraint(model, y1, MOI.GreaterThan(1.0))
    MOI.add_constraint(model, y2, MOI.GreaterThan(2.0))
    MOI.add_constraint(model, p, MOI.EqualTo(30.0))

    # Integrality
    MOI.add_constraint(model, d, MOI.Integer())
    MOI.add_constraint(model, za1, MOI.ZeroOne())
    MOI.add_constraint(model, za2, MOI.ZeroOne())

    return model
end

# ── Big LP Models ────────────────────────────────────────────────────────────
#
# 100 variables x_1_..x_100_
# Objective: maximize sum(i * x_i_ for i = 1:100)
# 50 constraints con, con_1..con_49:
#   con_k: sum(1/((k+1)+j) * x_j_ for j=1:100) <= (k+1)^2
# Bounds: x_i_ >= 0

function build_biglp(; perturbation::Float64 = 0.0, rng::Union{Nothing,AbstractRNG} = nothing)
    N = 100
    NCON = 50
    model = MOIU.Model{Float64}()

    xs = [add_var!(model, "x_$(i)_") for i in 1:N]

    # Objective
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    obj_terms = [MOI.ScalarAffineTerm(Float64(i), xs[i]) for i in 1:N]
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        MOI.ScalarAffineFunction(obj_terms, 0.0))

    # Constraints: con_k for k = 0..49
    for k in 0:(NCON-1)
        terms = [(1.0 / ((k + 1) + j), xs[j]) for j in 1:N]
        rhs = Float64((k + 1)^2) + perturbation
        name = k == 0 ? "con" : "con_$(k)"
        add_constraint!(model, terms, MOI.LessThan(rhs), name)
    end

    # Bounds
    for i in 1:N
        lb = rng === nothing ? 0.0 : rand(rng) * 0.001
        MOI.add_constraint(model, xs[i], MOI.GreaterThan(lb))
    end

    return model
end

# ── Tolerance Models ─────────────────────────────────────────────────────────
#
# Same structure as small models 1 & 2 but with all coefficients, bounds,
# and RHS perturbed by small random noise. Written only as MPS.

function perturb(value::Float64, rng::AbstractRNG; scale::Float64 = 1e-3)
    return value + rand(rng) * scale
end

function build_model1_tol(rng::AbstractRNG)
    model = MOIU.Model{Float64}()

    x   = add_var!(model, "x")
    y1  = add_var!(model, "y_1_")
    y2  = add_var!(model, "y_2_")
    z1  = add_var!(model, "z_1_")
    z2  = add_var!(model, "z_2_")
    z3  = add_var!(model, "z_3_")
    z4  = add_var!(model, "z_4_")
    z5  = add_var!(model, "z_5_")
    za  = add_var!(model, "z_a")
    w   = add_var!(model, "w")
    d   = add_var!(model, "d")

    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        MOI.ScalarAffineFunction([
            MOI.ScalarAffineTerm(perturb(2.0, rng), x),
            MOI.ScalarAffineTerm(perturb(3.0, rng), y1),
            MOI.ScalarAffineTerm(perturb(3.0, rng), y2),
            MOI.ScalarAffineTerm(perturb(1.0, rng), za),
            MOI.ScalarAffineTerm(perturb(1.0, rng), z1),
            MOI.ScalarAffineTerm(perturb(1.0, rng), z2),
            MOI.ScalarAffineTerm(perturb(1.0, rng), z3),
            MOI.ScalarAffineTerm(perturb(1.0, rng), z4),
            MOI.ScalarAffineTerm(perturb(1.0, rng), z5),
            MOI.ScalarAffineTerm(perturb(5.0, rng), d),
            MOI.ScalarAffineTerm(perturb(0.5, rng), w),
        ], 0.0))

    add_constraint!(model,
        [(perturb(1.0, rng), y2), (perturb(1.0, rng), y1)],
        MOI.GreaterThan(perturb(5.0, rng)), "y_con")
    add_constraint!(model,
        [(perturb(1.0, rng), za), (perturb(2.0, rng), z3), (perturb(2.0, rng), z2),
         (perturb(2.0, rng), z1), (perturb(2.0, rng), z4), (perturb(2.0, rng), z5)],
        MOI.GreaterThan(perturb(3.0, rng)), "c1")
    add_constraint!(model,
        [(perturb(1.0, rng), y1), (perturb(1.0, rng), y2),
         (perturb(1.0, rng), z1), (perturb(1.0, rng), z2), (perturb(1.0, rng), z3),
         (perturb(1.0, rng), z4), (perturb(1.0, rng), z5)],
        MOI.GreaterThan(perturb(5.0, rng)), "z_con")

    for z in [z1, z2, z3, z4, z5]
        MOI.add_constraint(model, z, MOI.GreaterThan(perturb(0.0, rng)))
        MOI.add_constraint(model, z, MOI.LessThan(perturb(1.0, rng)))
    end
    MOI.add_constraint(model, w, MOI.GreaterThan(perturb(30.0, rng)))
    MOI.add_constraint(model, x, MOI.GreaterThan(perturb(0.0, rng)))
    MOI.add_constraint(model, y1, MOI.GreaterThan(perturb(1.0, rng)))
    MOI.add_constraint(model, y2, MOI.GreaterThan(perturb(2.0, rng)))
    MOI.add_constraint(model, za, MOI.EqualTo(perturb(25.0, rng)))

    MOI.add_constraint(model, d, MOI.Integer())

    return model
end

function build_model2_tol(rng::AbstractRNG)
    model = MOIU.Model{Float64}()

    y1   = add_var!(model, "y_1_")
    y2   = add_var!(model, "y_2_")
    zvars = [add_var!(model, "z_$(i)_") for i in 1:10]
    za1  = add_var!(model, "z_a_1_")
    za2  = add_var!(model, "z_a_2_")
    p    = add_var!(model, "p")
    d    = add_var!(model, "d")
    t    = add_var!(model, "t")

    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    obj_terms = [
        MOI.ScalarAffineTerm(perturb(5.0, rng), y1),
        MOI.ScalarAffineTerm(perturb(5.0, rng), y2),
        [MOI.ScalarAffineTerm(perturb(1.0, rng), z) for z in zvars]...,
        MOI.ScalarAffineTerm(perturb(1.0, rng), za1),
        MOI.ScalarAffineTerm(perturb(1.0, rng), za2),
        MOI.ScalarAffineTerm(perturb(3.0, rng), p),
        MOI.ScalarAffineTerm(perturb(1.0, rng), d),
    ]
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        MOI.ScalarAffineFunction(obj_terms, 0.0))

    add_constraint!(model,
        [(perturb(1.0, rng), y1), (perturb(1.0, rng), y2)],
        MOI.GreaterThan(perturb(5.0, rng)), "y_con")
    add_constraint!(model,
        [(perturb(3.0, rng), p), (perturb(1.0, rng), za1), (perturb(1.0, rng), za2)],
        MOI.GreaterThan(perturb(7.0, rng)), "zcon")
    add_constraint!(model,
        [(perturb(1.0, rng), y1), (perturb(1.0, rng), y2),
         [(perturb(1.0, rng), z) for z in zvars]...],
        MOI.GreaterThan(perturb(5.0, rng)), "z_con")
    add_constraint!(model,
        [(perturb(2.0, rng), za1), (perturb(1.0, rng), za2)],
        MOI.EqualTo(perturb(3.0, rng)), "c1")

    for z in zvars
        MOI.add_constraint(model, z, MOI.GreaterThan(perturb(0.0, rng)))
        MOI.add_constraint(model, z, MOI.LessThan(perturb(1.0, rng)))
    end
    MOI.add_constraint(model, y1, MOI.GreaterThan(perturb(1.0, rng)))
    MOI.add_constraint(model, y2, MOI.GreaterThan(perturb(2.0, rng)))
    MOI.add_constraint(model, p, MOI.EqualTo(perturb(30.0, rng)))

    MOI.add_constraint(model, d, MOI.Integer())
    MOI.add_constraint(model, za1, MOI.ZeroOne())
    MOI.add_constraint(model, za2, MOI.ZeroOne())

    return model
end

# ── Main ─────────────────────────────────────────────────────────────────────

function main()
    println("Generating test models in $MODELS_DIR ...\n")

    # Small models
    println("Small models:")
    m1 = build_model1()
    write_model_to_file(m1, "model1.lp")
    write_model_to_file(m1, "model1.mps")

    m2 = build_model2()
    write_model_to_file(m2, "model2.lp")
    write_model_to_file(m2, "model2.mps")

    # Big LP models
    println("\nBig LP models:")
    biglp1 = build_biglp()
    write_model_to_file(biglp1, "modelbiglp1.lp")
    write_model_to_file(biglp1, "modelbiglp1.mps")

    rng_biglp2 = MersenneTwister(42)
    biglp2 = build_biglp(perturbation = rand(rng_biglp2) * 1e-3, rng = rng_biglp2)
    write_model_to_file(biglp2, "modelbiglp2.lp")
    write_model_to_file(biglp2, "modelbiglp2.mps")

    # Tolerance models (MPS only)
    println("\nTolerance models:")
    rng1 = MersenneTwister(123)
    rng2 = MersenneTwister(456)
    tol1 = build_model1_tol(rng1)
    tol2 = build_model2_tol(rng2)
    write_model_to_file(tol1, "model_tol_1.mps")
    write_model_to_file(tol2, "model_tol_2.mps")

    # Also write tolerance models to LP for completeness
    println("\nTolerance models (LP):")
    rng3 = MersenneTwister(789)
    rng4 = MersenneTwister(101)
    tol3 = build_model1_tol(rng3)
    tol4 = build_model2_tol(rng4)
    write_model_to_file(tol3, "modelbiglp_tol_1.lp")
    write_model_to_file(tol4, "modelbiglp_tol_2.lp")

    println("\nDone! All model files generated.")
end

main()
