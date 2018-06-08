#!/bin/bash

CONFIG=cce-8.7-fftw-libsci

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

module swap cce cce/8.7.0

cp $CONFIG.psmp $DIR/arch/$CONFIG.psmp

# Build CP2K
cd $DIR/makefiles
make ARCH=$CONFIG VERSION=psmp clean
if ! make ARCH=$CONFIG VERSION=psmp -j 256
then
    echo "Building CP2K failed"
    exit 1
fi
