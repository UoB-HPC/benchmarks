#!/bin/bash

DIR="$PWD/TeaLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/tea_leaf.f90" ]
then
    echo "Directory '$DIR' does not exist or does not contain tea_leaf.f90"
    exit 1
fi

cd $DIR

if ! make -B COMPILER=XL
then
    echo "Build failed"
    exit 1
fi

if [ ! -r tea_leaf ]
then
    echo "Build failed - no binary output"
    exit 1
fi

mv tea_leaf tea_leaf_pwr8

