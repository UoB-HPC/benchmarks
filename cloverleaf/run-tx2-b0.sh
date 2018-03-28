#!/bin/bash

DIR="$PWD/CloverLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/clover_leaf_tx2" ]
then
    echo "Directory '$DIR' does not exist or does not contain clover_leaf_tx2"
    exit 1
fi

cd $DIR

module purge
module load arm/hpc-compiler/18.1
module load openmpi/3.0.0/arm-18.1

cp InputDecks/clover_bm16.in clover.in

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=4
mpirun -np 64 --bind-to core ./clover_leaf_tx2
