#!/bin/bash

module swap cce cce/8.7.0

EXE=neutral.omp3.cce-8.7

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
