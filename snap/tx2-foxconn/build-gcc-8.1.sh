#!/bin/bash

module purge
module load gcc/8.1.0
module load openmpi/3.0.0/gcc-8.1

EXE=gsnap-gcc-8.1

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
