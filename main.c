#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "mpi.h"

// Julia headers (for initialization and gc commands)
#include "uv.h"
#include "julia.h"
#include "diffusion.h"

JULIA_DEFINE_FAST_TLS()

int main(int argc, char *argv[])
{
  // Initialization of libuv and julia
  uv_setup_args(argc, argv);
  libsupport_init();
  jl_parse_opts(&argc, &argv);
  jl_options.image_file = JULIAC_PROGRAM_LIBNAME;  // JULIAC_PROGRAM_LIBNAME defined on command-line for compilation
  julia_init(JL_IMAGE_JULIA_HOME);

  const int NDIMS = 2;
  int ret, nprocs, me, reorder = 0;
  int dims[] = {0,0}, coords[] = {0,0}, periods[] = {0,0};
  MPI_Comm comm=MPI_COMM_NULL;

  // Numerics
  size_t nx        = 64;      // Number of grid points in x dimension
  size_t ny        = 64;      // Number of grid points in y dimension
  size_t timesteps = 1000;    // Number of time steps

  double *T = (double *)malloc(nx*ny*sizeof(double));

  // Create Cartesian process topology
  MPI_Init(&argc, &argv);
  jl_eval_string("import MPI; MPI.run_init_hooks()");
  MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
  MPI_Dims_create(nprocs, NDIMS, dims);
  MPI_Cart_create(MPI_COMM_WORLD, NDIMS, dims, periods, reorder, &comm);
  MPI_Comm_rank(comm, &me);
  MPI_Cart_coords(comm, me, NDIMS, coords);

  // Initialize the heat capacity field
  for (int ix=0; ix<nx; ix++){
    for (int iy=0; iy<ny; iy++){
      T[iy*nx+ix] = 0.1;
    }
  };

  // Simulate heat diffusion calling shared library created by compiling Julia code
  ret = julia_diffusion(T, timesteps, nx, ny, comm);

  // Exit gracefully
  free(T);
  MPI_Finalize();
  jl_atexit_hook(ret);
  return ret;
}