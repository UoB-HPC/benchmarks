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

if [ ! -r "$DIR/tea_leaf.f90" ]
then
    echo "Directory '$DIR' does not exist or does not contain tea_leaf.f90"
    exit 1
fi

cd $DIR

rm -f $EXE
if ! make -B COMPILER=GNU \
    FLAGS_GNU="-Ofast -mcpu=thunderx2t99 -funroll-loops -cpp -ffree-line-length-none -ffast-math -ffp-contract=fast" \
    CFLAGS_GNU="-Ofast -mcpu=thunderx2t99 -funroll-loops -ffast-math -ffp-contract=fast"
then
    echo "Build failed"
    exit 1
fi

mv tea_leaf $EXE
