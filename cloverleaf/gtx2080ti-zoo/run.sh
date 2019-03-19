#!/bin/bash

cd $RUN_DIR
cp $SRC_DIR/InputDecks/clover_bm16.in $RUN_DIR/clover.in

if [ "$MODEL" == "omp-target" ]
then
    # Make sure we're using the C kernels for the OpenMP target version
    sed -i 's/ test_problem 5/ test_problem 5\'$'\n use_c_kernels/g' $RUN_DIR/clover.in
elif [ "$MODEL" == "opencl" ]
then
    # Make sure OCL_SRC_PREFIX is set so the kernel source files can be found
    export OCL_SRC_PREFIX=../CloverLeaf
fi

if [ "$MODEL" == "acc" ]
then
    mpirun -np 1 ./$BENCHMARK_EXE
else
    ./$BENCHMARK_EXE
fi