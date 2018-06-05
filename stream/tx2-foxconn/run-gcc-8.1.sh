#!/bin/bash

module purge
module load gcc/8.1.0

EXE=stream-gcc-8.1

if ! gcc -std=gnu99 -fopenmp \
    -Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 \
    ../stream.c -o $EXE
then
    echo "Build failed."
    exit 1
fi

# Best performance observed when only running 16 cores per socket.
export OMP_PROC_BIND=spread
export OMP_NUM_THREADS=32
./$EXE
