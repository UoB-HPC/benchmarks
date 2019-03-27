#!/bin/bash

cd $RUN_DIR
cp $SRC_DIR/InputDecks/clover_bm16.in $RUN_DIR/clover.in

# Make sure OCL_SRC_PREFIX is set so the kernel source files can be found
export OCL_SRC_PREFIX=../CloverLeaf

./$BENCHMARK_EXE
