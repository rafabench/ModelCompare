# ModelCompare.jl

A Julia package for comparing two optimization models (LP/MPS format) and producing a detailed diff report covering variables, bounds, objective function, and constraints.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/rafabench/ModelCompare")
```

## Quick Start

```julia
using ModelCompare

result = compare_models(
    "model1.lp",
    "model2.lp",
    outfile = "comparison.txt",
    tol = 1e-3,
)
```

The result is a `NamedTuple` with four fields:

- `variables` — a [`VariablesDiff`](@ref) showing which variables are unique to each model vs shared
- `bounds` — a [`BoundsDiff`](@ref) showing variable bound differences
- `objective` — an [`ObjectiveDiff`](@ref) showing objective sense and coefficient differences
- `constraints` — a [`ConstraintElementsDiff`](@ref) showing constraint coefficient and bound differences

## Output Sections

### Variable Names

Lists variables that belong only to Model 1, only to Model 2, or both.

### Variable Bounds

Shows bound differences for shared variables and bounds for variables unique to each model.

### Objective Function

Shows coefficient differences in the objective function. If the optimization senses differ (min vs max), that is reported as well.

### Constraints

Compares constraints **with matching names** across both models. Unmatched constraint names are not reported. For each matched constraint, coefficient and set (bound) differences are shown.

## Sorting Models

You can canonicalize a model file by sorting its variables and constraints alphabetically:

```julia
sort_model("model.lp")  # creates model.lp.sorted
```

## CLI Usage

After compilation (see `compile/compile.jl`):

```bash
ModelCompare --file1 model1.lp --file2 model2.lp -o result.txt -t 0.001
```
