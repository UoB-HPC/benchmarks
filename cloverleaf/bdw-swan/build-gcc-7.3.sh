#!/bin/bash

module swap PrgEnv-{cray,gnu}
module swap gcc gcc/7.3.0

EXE=clover_leaf_bdw_gcc-7.3

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
if ! make -B COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc \
    FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=broadwell -funroll-loops" \
    CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=broadwell -funroll-loops"
then
    echo "Build failed"
    exit 1
fi

mv clover_leaf $EXE
