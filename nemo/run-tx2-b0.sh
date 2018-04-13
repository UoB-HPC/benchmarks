#!/bin/bash

cd NEMO_benchmarks/NEMOGCM/CONFIG/TX2/EXP00

export NETCDF_DIR=/lustre/projects/cray/lanton/cce_8.7nightly-180214
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${NETCDF_DIR}/lib

export FORT_FMT_RECL=132
export OMP_NUM_THREADS=1
mpiexec -n 128 --bind-to hwthread:2 ./opa
grep "Average " timing.output
