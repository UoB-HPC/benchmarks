#!/bin/bash

module swap cce cce/8.7.1

EXE=clover_leaf_bdw_cce-8.7

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
if ! make -B COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc
then
    echo "Build failed"
    exit 1
fi

mv clover_leaf $EXE
