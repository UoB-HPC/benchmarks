#!/bin/bash

set -eu

# ng=32
NY=8 \
NZ=8 \
NPEY=2 \
NPEZ=1 \
NANG=36 \
NTHREADS=32 \
ICHUNK=16 \
envsubst <$BENCHMARK_TEMPLATE >$CONFIG.in

export OMP_NUM_THREADS=32
mpirun -np 2 --bind-to none ./$BENCHMARK_EXE $CONFIG.in $CONFIG.out
