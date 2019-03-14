#!/bin/bash

set -eu

cp "$SRC_DIR/Benchmarks/tea_bm_5.in" tea.in

export OMP_NUM_THREADS=32 OMP_PROC_BIND=true OMP_PLACES=cores
if [ "$MODEL" = omp ]; then
    mpirun -np 1 --bind-to none "./$BENCHMARK_EXE"
else
    "./$BENCHMARK_EXE"
fi
