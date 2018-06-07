#!/bin/bash

module purge
module load arm/hpc-compiler/18.3
module load openmpi/3.0.0/arm-18.3

EXE=gsnap-arm-18.3

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
if ! make -B TARGET=gsnap FFLAGS="-Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast -fopenmp"
then
    echo "Build failed"
    exit 1
fi

mv gsnap $EXE
