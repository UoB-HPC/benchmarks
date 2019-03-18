#!/bin/bash

set -eu

cp "$SRC_DIR/Benchmarks/tea_bm_5.in" tea.in

export OMP_PROC_BIND=spread OMP_PLACES=cores
if [[ "$COMPILER" =~ pgi ]]; then
    export OMP_NUM_THREADS=40
else
    export OMP_NUM_THREADS=80
fi

"./$BENCHMARK_EXE"
