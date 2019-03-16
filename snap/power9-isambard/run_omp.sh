#!/bin/bash

# ng=32
# Need to run with 2x20x2=80 threads to maximise all units, so runing with 4 MPI with 20 threads each
NY=8 \
NZ=8 \
NPEY=2 \
NPEZ=2 \
NANG=36 \
NTHREADS=20 \
ICHUNK=16 \
envsubst <$BENCHMARK_TEMPLATE >$CONFIG.in

export OMP_NUM_THREADS=20
mpirun -np 4 ./$BENCHMARK_EXE $CONFIG.in $CONFIG.out
