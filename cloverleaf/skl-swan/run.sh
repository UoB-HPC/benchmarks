#!/bin/bash
#PBS -q skl28
#PBS -l nodes=1
#PBS -l walltime=00:15:00
#PBS -joe

cd $RUN_DIR
if [ ! -x "$BENCHMARK_EXE" ]
then
    echo "Executable '$BENCHMARK_EXE' not found."
    exit 1
fi

# Run the benchmark
cp $SRC_DIR/InputDecks/clover_bm16.in clover.in
export OMP_NUM_THREADS=1
aprun -n 56 -d 1 -j 1 ./$BENCHMARK_EXE
