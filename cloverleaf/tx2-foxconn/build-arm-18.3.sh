#!/bin/bash

module purge
module load arm/hpc-compiler/18.1
module load openmpi/3.0.0/arm-18.1

EXE=clover_leaf_arm-18.3

DIR="$PWD/../CloverLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/clover.f90" ]
then
    echo "Directory '$DIR' does not exist or does not contain clover.f90"
    exit 1
fi

cd $DIR

rm -f $EXE
if ! make -B COMPILER=GNU \
    FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=native -funroll-loops" \
    CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=native -funroll-loops"
then
    echo "Build failed"
    exit 1
fi

mv clover_leaf $EXE
