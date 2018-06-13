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


module swap PrgEnv-{cray,gnu}
module swap gcc gcc/7.3.0

COMPILER=gcc-7.3
CONFIG=bdw-$COMPILER-mkl-libxsmm

# Build libxsmm if necessary
LIBXSMM_DIR="$PWD/libxsmm-$COMPILER"
if [ ! -f $LIBXSMM_DIR/BUILT ]
then
    mkdir -p $LIBXSMM_DIR
    pushd $LIBXSMM_DIR
    if ! make -f ../../libxsmm-1.9/Makefile AVX=2 -j 16
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
source /opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/bin/mklvars.sh intel64
make ARCH=$CONFIG VERSION=psmp clean
if ! make ARCH=$CONFIG VERSION=psmp -j 16
then
    echo "Building CP2K failed"
    exit 1
fi
