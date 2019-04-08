#!/bin/bash

# TODO: CRAY-FFTW vs MKL

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      gcc-8.2)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.2.0
          CMAKE_OPTS="-DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=AVX2_256"
          ;;
      intel-2019)
          module swap $PRGENV PrgEnv-intel
          module swap intel intel/19.0.0.117
          CMAKE_OPTS="-DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=AVX2_256"
          ;;
      *)
          echo
          echo "Invalid compiler '$COMPILER'."
          usage
          exit 1
          ;;
  esac

  case "$FFTLIB" in
      cray-fftw-3.3.8)
          module load cray-fftw/3.3.8.2
          ;;
      *)
          echo
          echo "Invalid FFT library '$FFTLIB'."
          usage
          exit 1
          ;;
  esac
}

SCRIPT="`realpath $0`"
export ARCH="bdw"
export NCORES=44
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="gcc-8.2 intel-2019"
export DEFAULT_COMPILER=gcc-8.2
export DEFAULT_FFTLIB=cray-fftw-3.3.8
export PBS_RESOURCES=":ncpus=44"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
