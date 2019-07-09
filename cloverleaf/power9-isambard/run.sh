#!/bin/bash

set -eu

cp $SRC_DIR/InputDecks/clover_bm16.in clover.in

case "$MODEL" in
    mpi)
        export OMP_NUM_THREADS=1
        mpirun -np 40 --bind-to core ./$BENCHMARK_EXE
        ;;
    omp)
        export OMP_NUM_THREADS=40 OMP_PROC_BIND=spread OMP_PLACES=cores
        mpirun -np 1 --bind-to none ./$BENCHMARK_EXE
        ;;
    acc)
        mpirun -np 1 ./$BENCHMARK_EXE
        ;;
    kokkos)
        export OMP_NUM_THREADS=40 OMP_PROC_BIND=spread OMP_PLACES=cores
        ./$BENCHMARK_EXE
        ;;
    *)
        echo "Unknown run configuration for model '$MODEL'"
        exit 1
        ;;
esac

