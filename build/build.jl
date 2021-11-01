using PackageCompiler, Libdl

PackageCompiler.create_library(".", "bundle";
                                lib_name="diffusion",
                                # project=joinpath(@__DIR__, ".."),
                                precompile_execution_file=[joinpath(@__DIR__, "generate_precompile.jl")],
                                precompile_statements_file=[joinpath(@__DIR__, "additional_precompile.jl")],
                                incremental=false,
                                filter_stdlibs=true,
                                include_lazy_artifacts=false)