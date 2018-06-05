#!/bin/bash

module purge
module load gcc/8.1.0
module load openmpi/3.1.0/gcc-8.1

EXE=clover_leaf_gcc-8.1

DIR="$PWD/../CloverLeaf_ref"
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

cp InputDecks/clover_bm16.in clover.in

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=4
mpirun -np 64 --bind-to core ./$EXE
