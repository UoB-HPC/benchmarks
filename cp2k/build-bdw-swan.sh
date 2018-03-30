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


module swap PrgEnv-{cray,gnu}

# Build libxsmm
rm -rf libxsmm-bdw
mkdir libxsmm-bdw
pushd libxsmm-bdw
if ! make -f ../libxsmm-1.9/Makefile AVX=2 -j 16
then
    echo "Building libxsmm failed"
    exit 1
fi
popd

sed 's#__LIBXSMMROOT__#'$PWD'/libxsmm-bdw#' swan-bdw.psmp >$DIR/arch/swan-bdw.psmp

# Build CP2K
cd $DIR/makefiles
source /opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/bin/mklvars.sh intel64
make ARCH=swan-bdw VERSION=psmp clean
if ! make ARCH=swan-bdw VERSION=psmp -j 16
then
    echo "Building CP2K failed"
    exit 1
fi
