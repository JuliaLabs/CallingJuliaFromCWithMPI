
#include "mpi.h"

// Julia headers (for initialization and gc commands)
#include "uv.h"
#include "julia.h"

// prototype of the C entry points in our application
int julia_diffusion(double* T, int timesteps, int nx, int ny, MPI_Comm comm);