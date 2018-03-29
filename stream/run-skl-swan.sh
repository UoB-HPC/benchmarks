#!/bin/bash

#PBS -N stream-skl
#PBS -o skl.out
#PBS -q skl28
#PBS -l nodes=1
#PBS -l walltime=00:05:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

module swap craype-{broadwell,x86-skylake}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

if ! icc -qopenmp -Ofast -xCORE-AVX512 -qopt-streaming-stores=always stream.c -o stream-skl
then
    echo "Build failed."
    exit 1
fi

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=56
aprun -n 1 -d 56 -j 1 -cc depth ./stream-skl
