#!/bin/bash

DIR="$PWD/cp2k-5.1"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/exe/tx2-b0/cp2k.psmp" ]
then
    echo "Directory '$DIR' does not exist or does not contain exe/tx2-b0/cp2k.psmp"
    exit 1
fi

module purge
module load gcc/7.2.0
module load openmpi/3.0.0/gcc-7.2

rm -rf tx2
mkdir -p tx2
cd tx2
export OMP_NUM_THREADS=2
mpirun -np 64 --bind-to core $DIR/exe/tx2-b0/cp2k.psmp -i $DIR/tests/QS/benchmark/H2O-64.inp | tee tx2.out
