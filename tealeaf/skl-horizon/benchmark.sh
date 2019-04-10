#!/bin/bash

function setup_env()
{
  module load craype-x86-skylake
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-8.7)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/8.7.9
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          ;;
      gcc-8.2)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.2.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -march=skylake-avx512 -funroll-loops -cpp -ffree-line-length-none"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -march=skylake-avx512 -funroll-loops"'
          ;;
      intel-2019)
          module swap $PRGENV PrgEnv-intel
          module swap intel intel/19.0.0.117
          MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_INTEL="-O3 -no-prec-div -fpp -align array64byte -xCORE-AVX512"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xCORE-AVX512"'
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
export PBS_RESOURCES=":ncpus=40:nodetype=SK40"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
