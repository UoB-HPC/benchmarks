#!/bin/bash

set -u

function setup_env()
{
  module swap craype-{broadwell,x86-skylake}
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
          MAKE_OPTS='TARGET=gsnap FORTRAN=ftn FFLAGS="-Ofast -march=skylake-avx512 -fopenmp"'
          ;;
      intel-2019)
          module swap $PRGENV PrgEnv-intel
          module swap intel intel/19.0.0.117
          export BENCHMARK_EXE=isnap
          MAKE_OPTS='TARGET=isnap FORTRAN=ftn FFLAGS="-O3 -qopenmp -ip -align array32byte -qno-opt-dynamic-align -fno-fnalias -fp-model fast -fp-speculation fast -xCORE-AVX512"'
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
export ARCH="skl"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="cce-8.7 gcc-8.2 intel-2019"
export DEFAULT_COMPILER=intel-2019
export PBS_RESOURCES=":ncpus=56"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
