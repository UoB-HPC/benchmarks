#!/bin/bash

set -eu

cd "$RUN_DIR"

"./$BENCHMARK_EXE" >> "BabelStream-$CONFIG.out"
