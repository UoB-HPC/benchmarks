#!/bin/bash

module swap PrgEnv-{cray,gnu}
module swap gcc gcc/7.3.0

TARGET=gsnap
CONFIG=gcc-7.3
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

if ! make -B TARGET=$TARGET FORTRAN=ftn \
    FFLAGS="-Ofast -march=broadwell -ffast-math -ffp-contract=fast -fopenmp"
then
    echo "Build failed"
    exit 1
fi

mv $TARGET $EXE
