#!/bin/bash

set -u

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-8.7)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/8.7.9
          export BENCHMARK_EXE=csnap
          MAKE_OPTS='TARGET=csnap FORTRAN=ftn FFLAGS=-hfp3 PP=cpp'
          ;;
      gcc-8.2)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.2.0
          export BENCHMARK_EXE=gsnap
          MAKE_OPTS='TARGET=gsnap FORTRAN=ftn FFLAGS="-Ofast -mcpu=native -fopenmp"'
          ;;
      arm-19.0)
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/19.0.0.1
          export BENCHMARK_EXE=gsnap
          MAKE_OPTS='TARGET=gsnap FORTRAN=ftn FFLAGS="-Ofast -mcpu=native -fopenmp"'
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
export COMPILERS="cce-8.7 gcc-8.2 arm-19.0"
export DEFAULT_COMPILER=cce-8.7
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
