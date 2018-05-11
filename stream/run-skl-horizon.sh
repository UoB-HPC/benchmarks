#!/bin/bash

#PBS -N stream-skl
#PBS -o skl20.out
#PBS -q batch
#PBS -l nodes=1
#PBS -l hostlist=\"[196-283]+[288-343]^\"
#PBS -l walltime=00:05:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

module load craype-x86-skylake
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

if ! icc -qopenmp -Ofast -xCORE-AVX512 -qopt-streaming-stores=always stream.c -o stream-skl
then
    echo "Build failed."
    exit 1
fi

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=40
aprun -n 1 -d 40 -j 1 -cc depth ./stream-skl
