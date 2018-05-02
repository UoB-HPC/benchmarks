#!/bin/bash

#BSUB -P CSC103SUMMITDEV
#BSUB -J stream-pwr8
#BSUB -nnodes 1
#BSUB -W 00:05
#BSUB -oo pwr8.out

if [ -z "$LS_SUBCWD" ]
then
    echo "Submit this script via bsub."
    exit 1
fi

cd $LS_SUBCWD

if ! xlc -std=gnu99 -O5 -qarch=pwr8 -qtune=pwr8 -qsmp=omp -qthreaded stream.c -o stream-pwr8
then
    echo "Build failed."
    exit 1
fi

export OMP_PROC_BIND=spread
export OMP_NUM_THREADS=20
jsrun -n 1 -a 1 -c 20 -b rs ./stream-pwr8


module load gcc/7.1.1-20170802
if !  gcc -std=gnu99 -O3 -mcpu=native -fopenmp stream.c -o stream-pwr8-gcc
then
    echo "Build failed."
    exit 1
fi

jsrun -n 1 -a 1 -c 20 -b rs ./stream-pwr8-gcc

