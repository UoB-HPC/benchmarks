#!/bin/bash

set -eu


export OMP_NUM_THREADS=80 OMP_PROC_BIND=spread OMP_PLACES=cores
"./$BENCHMARK_EXE" > $BENCHMARK_EXE.out
