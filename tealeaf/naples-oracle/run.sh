#!/bin/bash

#SBATCH --nodes 1
#SBATCH --ntasks-per-node 1

cp "$SRC_DIR/Benchmarks/tea_bm_5.in" tea.in

export OMP_PROC_BIND=true OMP_PLACES=cores
if [ "$MODEL" = omp ] && ! [[ "$COMPILER" =~ pgi ]]; then
    export OMP_NUM_THREADS=128
    mpirun -np 1 --bind-to none "./$BENCHMARK_EXE"
else
    export OMP_NUM_THREADS=128
    "./$BENCHMARK_EXE"
fi
