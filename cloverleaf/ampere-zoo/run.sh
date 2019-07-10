#!/bin/bash

set -eu

cp $SRC_DIR/InputDecks/clover_bm16.in clover.in

case "$MODEL" in
    mpi)
        export OMP_NUM_THREADS=1
        mpirun -np 32 --bind-to core ./$BENCHMARK_EXE
        ;;
    omp)
        export OMP_NUM_THREADS=32 OMP_PROC_BIND=true OMP_PLACES=cores
        mpirun -np 1 --bind-to none ./$BENCHMARK_EXE
        ;;
    kokkos)
        export OMP_NUM_THREADS=32 OMP_PROC_BIND=true OMP_PLACES=cores
        mpirun -np 1 --bind-to none ./$BENCHMARK_EXE
        ;;
    *)
        echo "Unknown run configuration for model '$MODEL'"
        exit 1
        ;;
esac

