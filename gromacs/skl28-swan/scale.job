#!/bin/bash
#PBS -q sk56-lg
#PBS -l walltime=01:00:00
#PBS -joe

set -u

cd "$PBS_O_WORKDIR"

# The Intel OpenMP runtime conflicts with Cray's aprun for thread affinity
export KMP_AFFINITY=disabled

export OMP_NUM_THREADS=4
export GMX_MAXBACKUP=-1
aprun -n $[NODES * 28] -N 28 -d 4 -j 2 "$BUILD_DIR/bin/gmx_mpi" mdrun \
      -s "$BENCHMARK_SCALE" \
      -ntomp 4 -noconfout
