#!/bin/bash

set -eu

cp $SRC_DIR/InputDecks/clover_bm16.in clover.in

case "$MODEL" in
    mpi)
        export OMP_NUM_THREADS=1
        mpirun -np 8 ./$BENCHMARK_EXE
        ;;
    omp)
        export OMP_NUM_THREADS=8 OMP_PROC_BIND=true
        mpirun -np 1 ./$BENCHMARK_EXE
        ;;
    *)
        echo "Unknown run configuration for model '$MODEL'"
        exit 1
        ;;
esac

