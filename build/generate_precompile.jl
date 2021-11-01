using Diffusion
import MPI

MPI.Init()
nx = ny   = Cint(8)
timesteps = Cint(100)
T         = zeros(nx, ny)
T_ptr     = pointer(T)
comm      = MPI.COMM_WORLD.val

Diffusion.julia_diffusion(T_ptr, timesteps, nx, ny, comm)

MPI.Finalize()