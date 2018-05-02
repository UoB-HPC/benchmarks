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

module load gcc/7.1.1-20170802

sed 's/march=native/mcpu=native/' Makefile > Makefile.patched

if ! make -B COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++ -f Makefile.patched
then
    echo "Build failed"
    exit 1
fi

mv neutral.omp3 neutral.omp3.pwr8
