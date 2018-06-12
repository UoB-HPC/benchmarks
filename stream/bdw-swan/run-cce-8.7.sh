#!/bin/bash

#PBS -N stream-cce-8.7
#PBS -o cce-8.7.out
#PBS -q large
#PBS -l nodes=1
#PBS -l walltime=00:05:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

module swap cce cce/8.7.1

EXE=stream-cce-8.7

if ! cc ../stream.c -o $EXE
then
    echo "Build failed."
    exit 1
fi

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=44
aprun -n 1 -d 44 -j 1 -cc depth ./$EXE
