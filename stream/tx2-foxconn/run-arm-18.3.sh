#!/bin/bash

module purge
module load arm/hpc-compiler/18.3

EXE=stream-arm-18.3

if ! armclang -std=gnu99 -fopenmp \
    -Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 \
    ../stream.c -o $EXE
then
    echo "Build failed."
    exit 1
fi

# Best performance observed when only running 16 cores per socket.
export OMP_PROC_BIND=true
export OMP_NUM_THREADS=32
./$EXE
