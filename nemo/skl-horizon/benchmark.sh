#!/bin/bash

function setup_env()
{
  module load craype-x86-skylake
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-8.7)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/8.7.9
          module load cray-netcdf-hdf5parallel/4.6.1.3
          export CPP=cpp
          export FC=ftn
          export LD=ftn
          export CC=cc
          export FCFLAGS="-em -s real64 -s integer32  -O2 -hflex_mp=intolerant -e0 -ez"
          export FFLAGS="-em -s real64 -s integer32  -O0 -hflex_mp=strict -e0 -ez -Rb"
          export FPPFLAGS="-P -E -traditional-cpp"
          export LDFLAGS="-hbyteswapio"
          export CFLAGS="-O0"
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
export COMPILERS="cce-8.7"
export DEFAULT_COMPILER=cce-8.7
export PBS_RESOURCES=":ncpus=40:nodetype=SK40"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
