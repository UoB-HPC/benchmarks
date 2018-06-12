#!/bin/bash

module swap PrgEnv-{cray,gnu}
module swap gcc gcc/7.3.0

EXE=tea_leaf_bdw_gcc-7.3

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
if ! make -B COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc \
    FLAGS_GNU="-Ofast -march=broadwell -funroll-loops -cpp -ffree-line-length-none -ffast-math -ffp-contract=fast" \
    CFLAGS_GNU="-Ofast -march=broadwell -funroll-loops -ffast-math -ffp-contract=fast"
then
    echo "Build failed"
    exit 1
fi

mv tea_leaf $EXE
