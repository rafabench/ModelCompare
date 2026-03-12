using Documenter
using ModelCompare

makedocs(
    sitename = "ModelCompare.jl",
    modules = [ModelCompare],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/rafabench/ModelCompare.git",
    devbranch = "master",
)
