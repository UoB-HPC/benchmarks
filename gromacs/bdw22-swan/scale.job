#!/bin/bash
#PBS -q bw44-lg
#PBS -l walltime=01:00:00
#PBS -joe

set -u

cd "$PBS_O_WORKDIR"

# The Intel OpenMP runtime conflicts with Cray's aprun for thread affinity
export KMP_AFFINITY=disabled

export OMP_NUM_THREADS=2
export GMX_MAXBACKUP=-1
aprun -n $[NODES * 44] -N 44 -d 2 -j 2 "$BUILD_DIR/bin/gmx_mpi" mdrun \
      -s "$BENCHMARK_SCALE" \
      -ntomp 2 -noconfout
