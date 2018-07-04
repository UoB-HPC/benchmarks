#!/bin/bash

cd $RUN_DIR
if [ ! -x "$BENCHMARK_EXE" ]
then
    echo "Executable '$BENCHMARK_EXE' not found."
    exit 1
fi

# Run the benchmark
cp $SRC_DIR/InputDecks/clover_bm16.in clover.in
export OMP_PROC_BIND=true
export OMP_NUM_THREADS=4
mpirun -np 64 --bind-to core ./$BENCHMARK_EXE
