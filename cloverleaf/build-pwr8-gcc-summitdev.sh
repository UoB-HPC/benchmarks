#!/bin/bash

DIR="$PWD/CloverLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/clover.f90" ]
then
    echo "Directory '$DIR' does not exist or does not contain clover.f90"
    exit 1
fi

cd $DIR

module load gcc/7.1.1-20170802

# Replace out of date flag
sed 's/march=native/mcpu=native/' Makefile > Makefile.patched

if ! make -f Makefile.patched -B COMPILER=GNU
then
    echo "Build failed"
    exit 1
fi

if [ ! -r clover_leaf ]
then
    echo "Build failed - no binary output"
    exit 1
fi

mv clover_leaf clover_leaf_pwr8
