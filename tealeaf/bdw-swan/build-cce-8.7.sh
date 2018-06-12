#!/bin/bash

module swap cce cce/8.7.1

EXE=tea_leaf_cce-8.7

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
if ! make -B COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc
then
    echo "Build failed"
    exit 1
fi

mv tea_leaf $EXE
