#!/bin/bash

set -eu

cp "$SRC_DIR/Benchmarks/tea_bm_5.in" tea.in

export OMP_PROC_BIND=true OMP_PLACES=cores
if [ "$MODEL" = omp ]; then 
    export OMP_NUM_THREADS=8
    mpirun -np 1 "./$BENCHMARK_EXE"
fi
