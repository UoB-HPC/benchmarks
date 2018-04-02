#!/bin/bash

#PBS -N opensbli-skl
#PBS -o skl.out
#PBS -e skl.err
#PBS -q skl28
#PBS -l nodes=1
#PBS -l walltime=00:20:00

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

DIR="$PWD/OpenSBLI/Benchmark"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/OpenSBLI_mpi_skl" ]
then
    echo "Directory '$DIR' does not exist or does not contain OpenSBLI_mpi_skl"
    exit 1
fi

module swap craype-{broadwell,x86-skylake}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128
module load cray-hdf5-parallel

cd $DIR
export OMP_NUM_THREADS=1
aprun -n 56 -d 1 -j 1 ./OpenSBLI_mpi_skl
