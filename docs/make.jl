using Documenter
using ModelCompare

makedocs(
    sitename = "ModelCompare.jl",
    modules = [ModelCompare],
    warnonly = [:missing_docs],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/rafabench/ModelCompare.git",
    devbranch = "master",
)
