#!/bin/bash

function setup_env()
{
  module swap craype-{broadwell,x86-skylake}
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-9.0)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/9.0.1
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_CRAY="-em -ra -h acc_model=fast_addr:no_deep_copy:auto_async_all -homp"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_CRAY="-Ofast -fopenmp -march=skylake-avx512 -funroll-loops"'
          ;;
      gcc-8.3)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.3.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -march=skylake-avx512 -funroll-loops -cpp -ffree-line-length-none"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -march=skylake-avx512 -funroll-loops"'
          ;;
      intel-2019)
          module swap $PRGENV PrgEnv-intel
          module swap intel intel/19.0.3.199
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
export ARCH="skl20"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="cce-9.0 gcc-8.3 intel-2019"
export DEFAULT_COMPILER=intel-2019
export PBS_RESOURCES=":ncpus=40"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
