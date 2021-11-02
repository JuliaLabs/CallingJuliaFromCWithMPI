# Simplified libDiffusion Demo

For a fully featured version that pulls in CUDA see https://github.com/omlins/libdiffusion

## Building

```
julia --project=. -e 'using Pkg; Pkg.instantiate()'
make
```

## Running

### Standalone
```
./main
```

### MPI

```
./mpiexecjl --project=. main
```
