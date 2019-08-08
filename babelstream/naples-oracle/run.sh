#!/bin/bash

#SBATCH --nodes 1
#SBATCH --ntasks-per-node 1

#set -eu

export OMP_NUM_THREADS=64 OMP_PROC_BIND=spread OMP_PLACES=cores
[ "$COMPILER" = pgi-18 ] && OMP_PROC_BIND=true # PGI compiler doesn't support OMP_PROC_BIND=spread

"./$BENCHMARK_EXE" > $BENCHMARK_EXE.out
