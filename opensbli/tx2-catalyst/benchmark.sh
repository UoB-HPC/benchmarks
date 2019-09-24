#!/bin/bash

function setup_env()
{
  case "$COMPILER" in
      gcc-8.2)
          module load Generic-AArch64/SUSE/12/gcc/8.2.0
          module load hmpt/2.20-gcc-8.2.0-new
          module load lib/hdf5/1.10.5-mpi
          export HDF5_INSTALL_PATH=/sw/lib/hdf5/1.10.5-mpi/
          export OPS_COMPILER=gnu
          OPS_MAKE_OPTS='CC=gcc CXX=g++ MPICPP=mpicxx MPICC=mpicc MPICXX=mpicxx CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=thunderx2t99 -ffp-contract=fast"'
          SBLI_MAKE_OPTS='CC=gcc CXX=g++ MPICPP=mpicxx MPICC=mpicc MPICXX=mpicxx CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
          ;;
      arm-19.2)
          module load Generic-AArch64/SUSE/12/arm-hpc-compiler/19.2
          module load hmpt/2.20-armpl-19.2.0-new
          export HDF5_INSTALL_PATH=/sw/lib/hdf5/1.10.5-mpi/
          export OPS_COMPILER=gnu
          OPS_MAKE_OPTS='CC=armclang CXX=armclang++ MPICPP=mpicxx MPICC=mpicc MPICXX=mpicxx CXXFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
          SBLI_MAKE_OPTS='CC=armclang CXX=armclang++ MPICPP=mpicxx MPICC=mpicc MPICXX=mpicxx CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
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
