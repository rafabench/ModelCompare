import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

import PackageCompiler

const COMPILE_DIR = @__DIR__
const DIR = dirname(COMPILE_DIR)
const BUILD_DIR = joinpath(COMPILE_DIR, "builddir")

@info("COMPILE-ModelCompare: Creating build dir")
if isdir(BUILD_DIR)
    rm(BUILD_DIR; force = true, recursive = true)
end
mkdir(BUILD_DIR)

CURRENT = pwd()
cd(DIR)

cd(CURRENT)

@info "COMPILE-ModelCompare: Starting PackageCompiler create_app function"
PackageCompiler.create_app(
    DIR,
    joinpath(BUILD_DIR, "ModelCompare");
    executables = ["ModelCompare" => "julia_main"],
    filter_stdlibs = true,
    incremental = false,
    include_lazy_artifacts = false,
    precompile_execution_file = joinpath(COMPILE_DIR, "compilation_script.jl"),
    force = true,
    include_transitive_dependencies = false
)

@info "COMPILE-PSRExample: Touch build.ok"
touch(joinpath(COMPILE_DIR, "build.ok"))

@info "COMPILE-PSRExample: Build Success"