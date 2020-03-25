#!/bin/bash
#PBS -q arm
#PBS -l walltime=00:15:00
#PBS -l select=1
#PBS -joe

export SRC_DIR=/home/br-hwaugh/benchmarks/cp2k/tx2-isambard/cp2k-5.1
export CONFIG=tx2_gcc-8.3_armpl-19.2_cray-fftw-3.3.8

export OMP_NUM_THREADS=1
aprun -n 64 -N 64 -d 1 -j 1\
    $SRC_DIR/exe/$CONFIG/cp2k.psmp \
    -i $SRC_DIR/tests/QS/benchmark/H2O-64.inp \
    | tee $CONFIG.out
