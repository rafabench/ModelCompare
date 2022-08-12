import Pkg
Pkg.activate(joinpath(dirname(@__DIR__), "revise"))
Pkg.instantiate()

using Revise

Pkg.activate(dirname(@__DIR__))
Pkg.instantiate()

using ModelComparator

@info("""
This session is using SDDP with Revise.jl.
For more information visit https://timholy.github.io/Revise.jl/stable/.
""")