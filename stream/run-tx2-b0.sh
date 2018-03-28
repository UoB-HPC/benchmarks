#!/bin/bash

module purge
module load arm/hpc-compiler/18.1

if ! armclang -std=gnu99 -fopenmp -Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 stream.c -o stream-tx2
then
    echo "Build failed."
    exit 1
fi

# Best performance observed when only running 16 cores per socket.
export OMP_PROC_BIND=true
export OMP_NUM_THREADS=32
./stream-tx2
