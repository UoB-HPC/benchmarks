#!/bin/bash

DIR="$PWD/CloverLeaf_ref"
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

module swap craype-{broadwell,mic-knl}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

if ! make -B COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc \
    FLAGS_INTEL="-O3 -no-prec-div -xMIC-AVX512" \
    CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xMIC-AVX512"
then
    echo "Build failed"
    exit 1
fi

mv clover_leaf clover_leaf_knl
