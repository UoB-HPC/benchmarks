#!/bin/bash

CONFIG=gcc8-fftw-openblas

DIR="$PWD/../cp2k-5.1"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/exe/$CONFIG/cp2k.psmp" ]
then
    echo "Directory '$DIR' does not exist or does not contain exe/$CONFIG/cp2k.psmp"
    exit 1
fi

module purge
module load gcc/8.1.0
module load openmpi/3.0.0/gcc-7.2

rm -rf $CONFIG
mkdir -p $CONFIG
cd $CONFIG
export OMP_NUM_THREADS=2
mpirun -np 64 --bind-to core $DIR/exe/$CONFIG/cp2k.psmp -i $DIR/tests/QS/benchmark/H2O-64.inp | tee $CONFIG.out
