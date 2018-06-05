#!/bin/bash

module purge
module load arm/hpc-compiler/18.3
module load openmpi/3.0.0/arm-18.3 # 3.1.0 fails?

EXE=tea_leaf-arm-18.3

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
