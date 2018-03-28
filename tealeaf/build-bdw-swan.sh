#!/bin/bash

DIR="$PWD/TeaLeaf_ref"
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

module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

if ! make -B COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc \
    FLAGS_INTEL="-O3 -no-prec-div -fpp -align array64byte -xCORE-AVX2" \
    CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xCORE-AVX2"
then
    echo "Build failed"
    exit 1
fi

mv tea_leaf tea_leaf_bdw
