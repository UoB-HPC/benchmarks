#!/bin/bash

function setup_env()
{
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
          FLAGS="-std=gnu99 -fopenmp -Ofast -mcpu=native"
          ;;
      arm-19.0)
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/19.0.0.1
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
export PLATFORM_DIR=`realpath $(dirname $SCRIPT)`
export PLATFORM="tx2"
export COMPILERS="cce-8.7 gcc-8.2 arm-19.0"
export DEFAULT_COMPILER=gcc-8.2
export -f setup_env

$PLATFORM_DIR/../common.sh $*
