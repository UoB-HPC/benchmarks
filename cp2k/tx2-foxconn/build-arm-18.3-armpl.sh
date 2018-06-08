#!/bin/bash

CONFIG=arm-18.3-armpl

DIR="$PWD/../cp2k-5.1"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/src/cp2k_info.F" ]
then
    echo "Directory '$DIR' does not exist or does not contain src/cp2k_info.F"
    exit 1
fi

module purge
module load arm/hpc-compiler/18.3
module load arm/perf-libs/18.3/arm-18.3
module load openmpi/3.0.0/arm-18.3

cp $CONFIG.psmp $DIR/arch/$CONFIG.psmp

# Build CP2K
cd $DIR/makefiles
make ARCH=$CONFIG VERSION=psmp clean
if ! make ARCH=$CONFIG VERSION=psmp -j 256
then
    echo "Building CP2K failed"
    exit 1
fi
