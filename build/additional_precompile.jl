import MPI

precompile(Tuple{typeof(Diffusion.julia_diffusion), Ptr{Floa64}, Cint, Cint, Cint, MPI.MPI_Comm})