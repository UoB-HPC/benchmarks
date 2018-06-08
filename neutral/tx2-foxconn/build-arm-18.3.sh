#!/bin/bash

module purge
module load arm/hpc-compiler/18.3

EXE=neutral.omp3.arm-18.3

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

sed -i '/defined(__powerpc__)$/s/$/ \&\& !defined(__aarch64__)/' Random123/features/gccfeatures.h

rm -f $EXE
if ! make -B COMPILER=GCC ARCH_COMPILER_CC=armclang ARCH_COMPILER_CPP=armclang++ \
    CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast"
then
    echo "Build failed"
    exit 1
fi

mv neutral.omp3 $EXE
