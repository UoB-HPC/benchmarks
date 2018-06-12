#!/bin/bash

module swap PrgEnv-{cray,gnu}
module swap gcc gcc/7.3.0

EXE=neutral.omp3.bdw.gcc-7.3

DIR="$PWD/../arch/neutral"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/neutral_data.c" ]
then
    echo "Directory '$DIR' does not exist or does not contain neutral_data.c"
    exit 1
fi

cd $DIR

rm -f $EXE
if ! make -B COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++ \
    CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -march=broadwell -ffast-math -ffp-contract=fast"
then
    echo "Build failed"
    exit 1
fi

mv neutral.omp3 $EXE
