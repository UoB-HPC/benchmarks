#!/bin/bash

module purge
module load arm/hpc-compiler/18.3

EXE=neutral.omp3.arm-18.3

DIR="$PWD/../arch/neutral"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/$EXE" ]
then
    echo "Directory '$DIR' does not exist or does not contain $EXE"
    exit 1
fi

cd $DIR

export OMP_PROC_BIND=close
export OMP_NUM_THREADS=256
./$EXE problems/csp.params
