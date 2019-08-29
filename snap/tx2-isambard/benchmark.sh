#!/bin/bash

set -u

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-9.0)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/9.0.1
          export BENCHMARK_EXE=csnap
          MAKE_OPTS='TARGET=csnap FORTRAN=ftn FFLAGS="-hfp3 -homp" PP=cpp'
          ;;
      gcc-8.3)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.3.0
          export BENCHMARK_EXE=gsnap
          MAKE_OPTS='TARGET=gsnap FORTRAN=ftn FFLAGS="-Ofast -mcpu=native -fopenmp"'
          ;;
      arm-19.2)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/19.2.0.0
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
export COMPILERS="cce-9.0 gcc-8.3 arm-19.2"
export DEFAULT_COMPILER=cce-9.0
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
