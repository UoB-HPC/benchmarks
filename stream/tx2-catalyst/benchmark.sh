#!/bin/bash

function setup_env()
{
  case "$COMPILER" in
      gcc-8.2)
          module load Generic-AArch64/SUSE/12/gcc/8.2.0
          CC=gcc
          FLAGS="-std=gnu99 -fopenmp -Ofast -mcpu=native"
          ;;
      arm-19.0)
          module load Generic-AArch64/SUSE/12/arm-hpc-compiler/19.0
          CC=armclang
          # NOTE: This version has a performance regression with -ffast-math
          FLAGS="-std=gnu99 -fopenmp -O3 -ffp-contract=fast -mcpu=native"
          ;;
      *)
          echo
          echo "Invalid compiler '$COMPILER'."
          usage
          exit 1
          ;;
  esac
}

SCRIPT=`realpath $0`
export ARCH="tx2"
export PLATFORM_DIR=`realpath $(dirname $SCRIPT)`
export COMPILERS="gcc-8.2 arm-19.0"
export DEFAULT_COMPILER=gcc-8.2
export -f setup_env

$PLATFORM_DIR/../common.sh $*
