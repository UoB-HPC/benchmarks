#!/bin/bash

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-8.7)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/8.7.9
          module load cray-hdf5-parallel/1.10.2.0
          export HDF5_INSTALL_PATH=$HDF5_DIR
          export OPS_COMPILER=cray
          OPS_MAKE_OPTS=''
          SBLI_MAKE_OPTS=''
          ;;
      gcc-8.2)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.2.0
          module load cray-hdf5-parallel/1.10.2.0
          export HDF5_INSTALL_PATH=$HDF5_DIR
          export OPS_COMPILER=gnu
          OPS_MAKE_OPTS='CC=cc CXX=CC MPICPP=CC MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=thunderx2t99 -ffp-contract=fast"'
          SBLI_MAKE_OPTS='CC=cc CXX=CC MPICPP=CC MPICC=cc MPICXX=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
          ;;
      arm-19.0)
          module swpa $PRGENV PrgEnv-allinea
          module swap allinea allinea/19.0.0.1
          module load cray-hdf5-parallel/1.10.2.0
          export HDF5_INSTALL_PATH=$HDF5_DIR
          export OPS_COMPILER=gnu
          OPS_MAKE_OPTS='CC=cc CXX=CC MPICPP=cc MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=thunderx2t99 -ffp-contract=fast"'
          SBLI_MAKE_OPTS='CC=cc CXX=CC MPICPP=cc MPICC=cc MPICXX=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
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
export COMPILERS="cce-8.7 gcc-8.2 arm-19.0"
export DEFAULT_COMPILER=cce-8.7
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
