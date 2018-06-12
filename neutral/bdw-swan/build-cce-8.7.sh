#!/bin/bash

module swap cce cce/8.7.1

EXE=neutral.omp3.bdw.cce-8.7

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
if ! make -B COMPILER=CRAY ARCH_COMPILER_CC=cc ARCH_COMPILER_CPP=CC \
    CFLAGS_CRAY="-hfp3"
then
    echo "Build failed"
    exit 1
fi

mv neutral.omp3 $EXE
