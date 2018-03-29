#!/bin/bash

DIR="$PWD/arch/neutral"
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

module purge
module load gcc/7.2.0

sed -i '/defined(__powerpc__)$/s/$/ \&\& !defined(__aarch64__)/' Random123/features/gccfeatures.h

if ! make -B COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++ \
    CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast"
then
    echo "Build failed"
    exit 1
fi

mv neutral.omp3 neutral.omp3.tx2
