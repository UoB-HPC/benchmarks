#!/bin/bash

function setup_env()
{
  case "$COMPILER" in
      gcc-8.2)
          module load hmpt/2.20-gcc-8.2.0-new
          module load Generic-AArch64/SUSE/12/gcc/8.2.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops -cpp -ffree-line-length-none"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          ;;
      arm-19.2)
          module load hmpt/2.20-armpl-19.2.0-new
          module load Generic-AArch64/SUSE/12/arm-hpc-compiler/19.2
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops -cpp -ffree-line-length-none"'
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

SCRIPT="`realpath $0`"
export ARCH="tx2"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="gcc-8.2 arm-19.2"
export DEFAULT_COMPILER=gcc-8.2
export PBS_RESOURCES=":ncpus=64:mpiprocs=64:ompthreads=1:mem=250gb"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
