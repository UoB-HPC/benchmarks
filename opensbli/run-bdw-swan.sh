#!/bin/bash

#PBS -N opensbli-bdw
#PBS -o bdw.out
#PBS -e bdw.err
#PBS -q large
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

if [ ! -r "$DIR/OpenSBLI_mpi_bdw" ]
then
    echo "Directory '$DIR' does not exist or does not contain OpenSBLI_mpi_bdw"
    exit 1
fi


module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128
module load cray-hdf5-parallel

cd $DIR
export OMP_NUM_THREADS=1
aprun -n 44 -d 1 -j 1 ./OpenSBLI_mpi_bdw
