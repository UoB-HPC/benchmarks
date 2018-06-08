#!/bin/bash

module swap cce cce/8.7.0

EXE=csnap-cce-8.7

DIR="$PWD/../SNAP"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/src/snap_main.f90" ]
then
    echo "Directory '$DIR' does not exist or does not contain src/snap_main.f90"
    exit 1
fi

cd $DIR/src

rm -f $EXE
if ! make -B TARGET=csnap FORTRAN=ftn FFLAGS=-hfp3 PP=cpp
then
    echo "Build failed"
    exit 1
fi

mv csnap $EXE
