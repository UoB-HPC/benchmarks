#!/bin/bash

DIR="$PWD/cp2k-5.1"
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
module load gcc/7.2.0
module load openmpi/3.0.0/gcc-7.2

cp tx2-b0.psmp $DIR/arch/tx2-b0.psmp

# Build CP2K
cd $DIR/makefiles
make ARCH=tx2-b0 VERSION=psmp clean
if ! make ARCH=tx2-b0 VERSION=psmp -j 64
then
    echo "Building CP2K failed"
    exit 1
fi
