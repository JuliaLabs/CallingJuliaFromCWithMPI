OS := $(shell uname)
DLEXT := $(shell julia -e 'using Libdl; print(Libdl.dlext)')

JULIA := julia
# JULIA_DIR := $(shell $(JULIA) -e 'print(dirname(Sys.BINDIR))')
JL_SHARE = $(shell julia -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags)
# LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
# LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)

# JL_PRIVATE_LIBDIR = $(shell julia -e 'print(joinpath(Sys.BINDIR, Base.PRIVATE_LIBDIR))')
LIBDIR := $(abspath bundle/lib)
LDFLAGS += -L$(LIBDIR) -L$(LIBDIR)/julia
LDLIBS += -ljulia -ljulia-internal -ldiffusion
CFLAGS += -I$(abspath bundle/include) -I. 

ifeq ($(OS), Darwin)
  WLARGS := -Wl,-rpath,"$(LIBDIR)" -Wl,-rpath,"@executable_path -Wl,-rpath,"$(LIBDIR)/julia"
else
  WLARGS := -Wl,-rpath,"$(LIBDIR):$$ORIGIN" -Wl,-rpath,"$(LIBDIR)/julia:$$ORIGIN"
endif

MAIN := main

ifeq ($(OS), WINNT)
  MAIN := $(MAIN).exe
endif

.DEFAULT_GOAL := main

$(LIBDIR)/libdiffusion.$(DLEXT): build/build.jl src/Diffusion.jl build/generate_precompile.jl build/additional_precompile.jl
	JULIA_CUDA_USE_BINARYBUILDER=false JULIA_MPI_BINARY=system $(JULIA) --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'
	# JULIA_CUDA_USE_BINARYBUILDER=false JULIA_MPI_BINARY=system $(JULIA) --startup-file=no --project=. -e 'using Pkg; Pkg.build()'
	$(JULIA) --startup-file=no --project=build -e 'using Pkg; Pkg.instantiate()'
	JULIA_CUDA_USE_BINARYBUILDER=false $(JULIA_MPIEXEC) $(JULIA_MPIEXEC_ARGS) $(JULIA) --startup-file=no --project=build $<

main.o: main.c
	$(CC) $^ -c -o $@ $(CFLAGS) -DJULIAC_PROGRAM_LIBNAME=\"bundle/lib/libdiffusion.$(DLEXT)\"

$(MAIN): main.o $(LIBDIR)/libdiffusion.$(DLEXT)
	$(CC) -o $@ $< $(LDFLAGS) $(LDLIBS) $(WLARGS)

.PHONY: clean
clean:
	$(RM) *~ *.o *.$(DLEXT) main
	$(RM) -rf bundle