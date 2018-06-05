#!/bin/bash

module swap cce cce/8.7.0

EXE=stream-cce-8.7.0

if ! cc ../stream.c -o $EXE
then
    echo "Build failed."
    exit 1
fi

# Best performance observed when only running 16 cores per socket.
export OMP_PROC_BIND=true
export OMP_NUM_THREADS=32
./$EXE
