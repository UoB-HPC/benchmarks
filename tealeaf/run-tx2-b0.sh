#!/bin/bash

DIR="$PWD/TeaLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/tea_leaf_tx2" ]
then
    echo "Directory '$DIR' does not exist or does not contain tea_leaf_tx2"
    exit 1
fi

cd $DIR

module purge
module load gcc/7.2.0
module load openmpi/3.0.0/gcc-7.2

cp Benchmarks/tea_bm_5.in tea.in

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=2
mpirun -np 64 --bind-to core ./tea_leaf_tx2
