#!/bin/bash

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-11.0)
          module load cdt/20.12
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/11.0.1
          MAKE_OPTS='COMPILER=CRAY ARCH=thunderx2t99 MODEL=omp-task'
          ;;
      gcc-10.1)
          module load cdt/20.12
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/10.1.0
          MAKE_OPTS='COMPILER=GNU ARCH=thunderx2t99 MODEL=omp-task'
          ;;
      arm-20.0)
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/20.0.0.0
          MAKE_OPTS='COMPILER=ARM ARCH=thunderx2t99 MODEL=omp-task'
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
export SYSTEM="isambard"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="cce-11.0 gcc-10.1 arm-20.0"
export DEFAULT_COMPILER=gcc-10.1
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
