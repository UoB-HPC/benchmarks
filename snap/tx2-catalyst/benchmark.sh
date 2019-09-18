#!/bin/bash

function setup_env()
{
  case "$COMPILER" in
      gcc-8.2)
          module load hmpt/2.20-gcc-8.2.0-new
          module load Generic-AArch64/SUSE/12/gcc/8.2.0
          export BENCHMARK_EXE=gsnap
          MAKE_OPTS='TARGET=gsnap FORTRAN=mpif90 FFLAGS="-Ofast -mcpu=native -fopenmp"'
          ;;
      arm-19.2)
          module load hmpt/2.20-armpl-19.2.0-new
          module load Generic-AArch64/SUSE/12/arm-hpc-compiler/19.2
          export BENCHMARK_EXE=gsnap
          MAKE_OPTS='TARGET=gsnap FORTRAN=mpif90 FFLAGS="-Ofast -mcpu=native -fopenmp"'
          ;;
      *)
          echo
          echo "Invalid compiler '$COMPILER'."
          usage
          exit 1
          ;;
  esac
}

SCRIPT="`realpath $0`"
export ARCH="tx2"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="gcc-8.2 arm-19.2"
export DEFAULT_COMPILER=gcc-8.2
export PBS_RESOURCES=":ncpus=64:mpiprocs=2:ompthreads=32:mem=250gb"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
