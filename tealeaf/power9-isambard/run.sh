#!/bin/bash

set -eu

cp "$SRC_DIR/Benchmarks/tea_bm_5.in" tea.in

export OMP_NUM_THREADS=80 OMP_PROC_BIND=spread OMP_PLACES=cores
"./$BENCHMARK_EXE"
