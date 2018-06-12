#!/bin/bash

#PBS -N stream-intel-2018
#PBS -o intel-2018.out
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

module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

EXE=stream-intel-2018

if ! icc -qopenmp -Ofast -xCORE-AVX2 -qopt-streaming-stores=always ../stream.c -o $EXE
then
    echo "Build failed."
    exit 1
fi

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=44
aprun -n 1 -d 44 -j 1 -cc depth ./$EXE
