#!/bin/bash

function setup_env()
{
  case "$COMPILER" in
      gcc-8.2)
          module load Generic-AArch64/SUSE/12/gcc/8.2.0
          module load hmpt/2.20-gcc-8.2.0-new
          module load tools/cmake/3.14.1
          CMAKE_OPTS="-DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx"
          CMAKE_OPTS="$CMAKE_OPTS -DCMAKE_C_FLAGS=-mcpu=thunderx2t99 -DCMAKE_CXX_FLAGS=-mcpu=thunderx2t99"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=ARM_NEON_ASIMD"
          ARMPL_VARIANT=gcc-8.2.0
          ;;
      arm-19.2)
          module load Generic-AArch64/SUSE/12/arm-hpc-compiler/19.2
          module load hmpt/2.20-armpl-19.2.0-new
          module load tools/cmake/3.14.1
          CMAKE_OPTS="-DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx"
          CMAKE_OPTS="$CMAKE_OPTS -DCMAKE_C_FLAGS=-mcpu=thunderx2t99 -DCMAKE_CXX_FLAGS=-mcpu=thunderx2t99"
          CMAKE_OPTS="${CMAKE_OPTS} -DGMX_SIMD=ARM_NEON_ASIMD"
          ARMPL_VARIANT=arm-hpc-compiler-19.2
          ;;
      *)
          echo
          echo "Invalid compiler '$COMPILER'."
          usage
          exit 1
          ;;
  esac

  case "$FFTLIB" in
      armpl-19.2)
          if [ -z "$ARMPL_VARIANT" ]
          then
              echo
              echo "Using armpl is not supported for $COMPILER."
              echo
              exit 1
          fi
          module load ThunderX2CN99/SUSE/12/$ARMPL_VARIANT/armpl/19.2.0
          CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_LIBRARY=${ARMPL_DIR}/lib/libarmpl.so"
          CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_INCLUDE_DIR=${ARMPL_DIR}/include"
          ;;
      fftw-3.3.8)
          CMAKE_OPTS="$CMAKE_OPTS -DGMX_BUILD_OWN_FFTW=ON"
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
export COMPILERS="gcc-8.2 arm-19.2"
export FFTLIBS="fftw-3.3.8 armpl-19.2"
export DEFAULT_COMPILER=gcc-8.2
export DEFAULT_FFTLIB=fftw-3.3.8
export PBS_RESOURCES=":ncpus=64:mpiprocs=64:ompthreads=1:mem=250gb"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
