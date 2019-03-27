#!/bin/bash

function setup_env()
{
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
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          ;;
      arm-19.0)
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/19.0.0.1
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
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
export DEFAULT_COMPILER=cce-8.7
export -f setup_env

$PLATFORM_DIR/../common.sh $*
