module Diffusion

import MPI
using ImplicitGlobalGrid
using CairoMakie

@views interior(A) = A[2:end-1,2:end-1]

@views north(A) = A[1:end-2,2:end-1]
@views south(A) = A[3:end,  2:end-1]
@views east(A)  = A[2:end-1,1:end-2]
@views west(A)  = A[2:end-1,3:end]

function diffusion(T, timesteps, comm)
    nx, ny = size(T)
    me, dims = init_global_grid(nx, ny, 1; init_MPI=!MPI.Initialized(), comm=comm, reorder=0)  # Initialize the implicit global grid

    if me == 0
        nx_v = (nx-2)*dims[1]
        ny_v = (ny-2)*dims[2]
        T_v  = zeros(nx_v, ny_v)
    else
        T_v  = nothing
    end
    gather!(Array(interior(T)), T_v)

    if me == 0
        node = Node(T_v)
        fig = heatmap(node, colorrange = (0.0, 2.0))
        video = VideoStream(fig, framerate=3)
    end

    for t in 1:timesteps
        interior(T) .-= interior(T) .- ((north(T) .+ south(T) .+ east(T) .+ west(T)) ./ 4.0)
        update_halo!(T)

        if t % 2 == 0
            gather!(Array(interior(T)), T_v)
            if me == 0
                node[] = T_v
                recordframe!(video)
            end
        end
    end
    if me == 0
        save("diffusion.mp4", video)
    end
end

Base.@ccallable function julia_diffusion(T_ptr::Ptr{Float64}, timesteps::Cint, nx::Cint, ny::Cint, comm_c::MPI.MPI_Comm)::Cint
    try
        comm = MPI.Comm_dup(MPI.Comm(comm_c))
        T    = unsafe_wrap(Array, T_ptr, (Int64(nx), Int64(ny)), own=false)
        diffusion(T, timesteps, comm)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

end # module
