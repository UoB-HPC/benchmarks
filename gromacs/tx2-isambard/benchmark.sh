#!/bin/bash

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      gcc-8.2)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.2.0
          CMAKE_OPTS="-DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC"
          CMAKE_OPTS="$CMAKE_OPTS -DCMAKE_C_FLAGS=-mcpu=thunderx2t99 -DCMAKE_CXX_FLAGS=-mcpu=thunderx2t99"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=ARM_NEON_ASIMD"
          ARMPL_VARIANT=gcc_8.2.0
          ;;
      arm-19.0)
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/19.0.0.1
          CMAKE_OPTS="-DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC"
          CMAKE_OPTS="$CMAKE_OPTS -DCMAKE_C_FLAGS=-mcpu=thunderx2t99 -DCMAKE_CXX_FLAGS=-mcpu=thunderx2t99"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=ARM_NEON_ASIMD"
          ARMPL_VARIANT=arm-hpc-compiler_19.0
          ;;
      *)
          echo
          echo "Invalid compiler '$COMPILER'."
          usage
          exit 1
          ;;
  esac

  case "$FFTLIB" in
      armpl-19.0)
          if [ -z "$ARMPL_VARIANT" ]
          then
              echo
              echo "Using armpl is not supported for $COMPILER."
              echo
              exit 1
          fi
          ARMPL_DIR=/opt/allinea/19.0.0/opt/arm/armpl-19.0.0_ThunderX2CN99_SUSE-12_${ARMPL_VARIANT}_aarch64-linux
          CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_LIBRARY=${ARMPL_DIR}/lib/libarmpl.so"
          CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_INCLUDE_DIR=${ARMPL_DIR}/include"
          ;;
      cray-fftw-3.3.8)
          CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_LIBRARY=/opt/cray/pe/fftw/3.3.8.2/arm_thunderx2/lib/libfftw3f.a"
          CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_INCLUDE_DIR=/opt/cray/pe/fftw/3.3.8.2/arm_thunderx2/include"
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
export ARCH="tx2"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="gcc-8.2 arm-19.0"
export DEFAULT_COMPILER=gcc-8.2
export DEFAULT_FFTLIB=cray-fftw-3.3.8
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
