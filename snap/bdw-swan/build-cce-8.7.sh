#!/bin/bash

module swap cce cce/8.7.1

TARGET=csnap
CONFIG=cce-8.7
EXE=$TARGET-$CONFIG

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

if ! make -B TARGET=$TARGET FORTRAN=ftn FFLAGS=-hfp3 PP=cpp
then
    echo "Build failed"
    exit 1
fi

mv $TARGET $EXE
