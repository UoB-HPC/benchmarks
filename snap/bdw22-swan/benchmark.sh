#!/bin/bash

set -u

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-9.0)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/9.0.1
          export BENCHMARK_EXE=csnap
          MAKE_OPTS='TARGET=csnap FORTRAN=ftn FFLAGS="-hfp3 -homp" PP=cpp'
          ;;
      gcc-8.3)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.3.0
          export BENCHMARK_EXE=gsnap
          MAKE_OPTS='TARGET=gsnap FORTRAN=ftn FFLAGS="-Ofast -march=broadwell -fopenmp"'
          ;;
      intel-2019)
          module swap $PRGENV PrgEnv-intel
          module swap intel intel/19.0.3.199
          export BENCHMARK_EXE=isnap
          MAKE_OPTS='TARGET=isnap FORTRAN=ftn FFLAGS="-O3 -qopenmp -ip -align array32byte -qno-opt-dynamic-align -fno-fnalias -fp-model fast -fp-speculation fast -xCORE-AVX2"'
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
export ARCH="bdw22"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="cce-9.0 gcc-8.3 intel-2019"
export DEFAULT_COMPILER=intel-2019
export PBS_RESOURCES=":ncpus=44"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
