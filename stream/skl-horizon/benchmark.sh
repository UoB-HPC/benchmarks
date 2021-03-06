#!/bin/bash

function setup_env()
{
  module load craype-x86-skylake
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-8.7)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/8.7.9
          CC=cc
          FLAGS=""
          ;;
      gcc-8.2)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.2.0
          CC=gcc
          FLAGS="-fopenmp -Ofast -march=skylake-avx512"
          ;;
      intel-2019)
          module swap $PRGENV PrgEnv-intel
          module swap intel intel/19.0.0.117
          CC=icc
          FLAGS="-qopenmp -Ofast -xCORE-AVX512 -qopt-streaming-stores=always"
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
export DEFAULT_COMPILER=cce-8.7
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
