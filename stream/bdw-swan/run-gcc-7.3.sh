#!/bin/bash

#PBS -N stream-gcc-7.3
#PBS -o gcc-7.3.out
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

module swap PrgEnv-{cray,gnu}
module swap gcc gcc/7.3.0

EXE=stream-gcc-7.3

if ! gcc -fopenmp -Ofast -ffast-math -ffp-contract=fast -march=broadwell ../stream.c -o $EXE
then
    echo "Build failed."
    exit 1
fi

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=44
aprun -n 1 -d 44 -j 1 -cc depth ./$EXE
