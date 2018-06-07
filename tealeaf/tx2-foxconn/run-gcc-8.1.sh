#!/bin/bash

module purge
module load gcc/8.1.0
module load openmpi/3.0.0/gcc-8.1

EXE=tea_leaf-gcc-8.1

DIR="$PWD/../TeaLeaf_ref"
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

cp Benchmarks/tea_bm_5.in tea.in

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=2
mpirun -np 64 --bind-to core ./$EXE
