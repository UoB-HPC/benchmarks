#!/bin/bash

module purge
module load gcc/8.1.0
module load openmpi/3.0.0/gcc-8.1
module load hdf5-parallel

EXE=OpenSBLI_mpi_gcc-8.1

DIR="$PWD/../OpenSBLI/Benchmark"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/$EXE" ]
then
    echo "Directory '$DIR' does not exist or does not contain $EXE"
    exit 1
fi
cd $DIR
export OMP_NUM_THREADS=1
mpirun -np 64 --bind-to core ./$EXE
