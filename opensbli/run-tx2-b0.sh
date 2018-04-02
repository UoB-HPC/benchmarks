#!/bin/bash

DIR="$PWD/OpenSBLI/Benchmark"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/OpenSBLI_mpi_tx2" ]
then
    echo "Directory '$DIR' does not exist or does not contain OpenSBLI_mpi_tx2"
    exit 1
fi

module load hdf5-parallel

cd $DIR
export OMP_NUM_THREADS=1
mpirun -np 64 --bind-to core ./OpenSBLI_mpi_tx2
