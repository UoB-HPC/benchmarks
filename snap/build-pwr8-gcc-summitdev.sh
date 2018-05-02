#!/bin/bash

DIR="$PWD/SNAP"
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

module load gcc/7.1.1-20170802

if ! make -B TARGET=gsnap FFLAGS="-O3 -mcpu=native -fopenmp"
then
    echo "Build failed"
    exit 1
fi

mv gsnap gsnap-pwr8
