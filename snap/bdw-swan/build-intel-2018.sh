#!/bin/bash

module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

TARGET=isnap
CONFIG=intel-2018
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
    FFLAGS="-O3 -qopenmp -ip -align array32byte -qno-opt-dynamic-align -fno-fnalias -fp-model fast -fp-speculation fast -xCORE-AVX2"
then
    echo "Build failed"
    exit 1
fi

mv $TARGET $EXE
