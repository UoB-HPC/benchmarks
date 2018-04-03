#!/bin/bash

#PBS -N stream-knl
#PBS -o knl.out
#PBS -q knl64
#PBS -l nodes=1
#PBS -l os=CLE_quad_flat
#PBS -l walltime=00:05:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

module swap craype-{broadwell,mic-knl}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

if ! icc -qopenmp -Ofast -xMIC-AVX512 -qopt-streaming-stores=always stream.c -o stream-knl
then
    echo "Build failed."
    exit 1
fi

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=64
aprun -n 1 -d 64 -j 1 -cc depth numactl -m 1 ./stream-knl
