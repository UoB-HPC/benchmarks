#!/bin/bash

module purge
module load gcc/8.1.0

EXE=neutral.omp3.gcc-8.1

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
