#!/bin/bash

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

module swap cce cce/8.7.1

COMPILER=cce-8.7
CONFIG=bdw-$COMPILER-fftw-libxsmm

# Build libxsmm if necessary
LIBXSMM_DIR="$PWD/libxsmm-$COMPILER"
if [ ! -f $LIBXSMM_DIR/BUILT ]
then
    mkdir -p $LIBXSMM_DIR
    pushd $LIBXSMM_DIR
    if ! make -f ../../libxsmm-1.9/Makefile AVX=2 -j 16 CC=cc CXX=CC FC=ftn
    then
        echo "Building libxsmm failed"
        exit 1
    fi
    touch BUILT
    popd
fi

sed 's#__LIBXSMMROOT__#'$LIBXSMM_DIR'#' $CONFIG.psmp >$DIR/arch/$CONFIG.psmp

# Build CP2K
cd $DIR/makefiles
make ARCH=$CONFIG VERSION=psmp clean
if ! make ARCH=$CONFIG VERSION=psmp -j 16
then
    echo "Building CP2K failed"
    exit 1
fi
