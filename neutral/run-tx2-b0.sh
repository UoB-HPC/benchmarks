#!/bin/bash

DIR="$PWD/arch/neutral"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/neutral.omp3.tx2" ]
then
    echo "Directory '$DIR' does not exist or does not contain neutral.omp3.tx2"
    exit 1
fi

cd $DIR

module purge
module load gcc/7.2.0

export OMP_PROC_BIND=close
export OMP_NUM_THREADS=256
./neutral.omp3.tx2 problems/csp.params
