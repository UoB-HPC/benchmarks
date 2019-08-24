#!/bin/bash

function setup_env()
{
  module swap craype-{broadwell,x86-skylake}
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-9.0)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/9.0.1
          CMAKE_OPTS="-DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=AVX_512"
          ;;
      gcc-8.3)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.3.0
          CMAKE_OPTS="-DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=AVX_512"
          ;;
      intel-2019)
          module swap $PRGENV PrgEnv-intel
          module swap intel intel/19.0.3.199
          CMAKE_OPTS="-DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=AVX_512"
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
          module load cray-fftw/3.3.8.3
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
export ARCH="skl20"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="cce-9.0 gcc-8.3 intel-2019"
export FFTLIBS="cray-fftw-3.3.8"
export DEFAULT_COMPILER=gcc-8.3
export DEFAULT_FFTLIB=cray-fftw-3.3.8
export PBS_RESOURCES=":ncpus=40"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
