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

if [ ! -r "$DIR/clover.f90" ]
then
    echo "Directory '$DIR' does not exist or does not contain clover.f90"
    exit 1
fi

cd $DIR

rm -f $EXE
if ! make -B COMPILER=GNU \
    FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops" \
    CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"
then
    echo "Build failed"
    exit 1
fi

mv clover_leaf $EXE
