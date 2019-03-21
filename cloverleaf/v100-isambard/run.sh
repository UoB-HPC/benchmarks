#!/bin/bash
#PBS -q pascalq
#PBS -l nodes=1:ppn=36
#PBS -l walltime=00:30:00
#PBS -joe

set -eu

cd "$RUN_DIR"

cp "$SRC_DIR/InputDecks/clover_bm16.in" "$RUN_DIR/clover.in"

export OMP_NUM_THREADS=1
"./$BENCHMARK_EXE"
