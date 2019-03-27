#!/bin/bash

set -eu

cd "$RUN_DIR"

cp "$SRC_DIR/InputDecks/clover_bm16.in" "$RUN_DIR/clover.in"

export OCL_SRC_PREFIX=../CloverLeaf

"./$BENCHMARK_EXE"
