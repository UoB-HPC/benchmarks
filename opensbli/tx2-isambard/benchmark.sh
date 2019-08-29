#!/bin/bash

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-9.0)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/9.0.1
          module load cray-hdf5-parallel/1.10.5.0
          export HDF5_INSTALL_PATH=$HDF5_DIR
          export OPS_COMPILER=cray
          OPS_MAKE_OPTS='MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffp-contract=fast"'
          SBLI_MAKE_OPTS='MPICPP=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -ffp-contract=fast"'
          ;;
      gcc-8.3)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.3.0
          module load cray-hdf5-parallel/1.10.5.0
          export HDF5_INSTALL_PATH=$HDF5_DIR
          export OPS_COMPILER=gnu
          OPS_MAKE_OPTS='CC=cc CXX=CC MPICPP=CC MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=thunderx2t99 -ffp-contract=fast"'
          SBLI_MAKE_OPTS='CC=cc CXX=CC MPICPP=CC MPICC=cc MPICXX=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
          ;;
      arm-19.2)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/19.2.0.0
          module load cray-hdf5-parallel/1.10.5.0
          export HDF5_INSTALL_PATH=$HDF5_DIR
          export OPS_COMPILER=gnu
          OPS_MAKE_OPTS='CC=cc CXX=CC MPICPP=CC MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
          SBLI_MAKE_OPTS='CC=cc CXX=CC MPICPP=CC MPICC=cc MPICXX=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
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
export COMPILERS="cce-9.0 gcc-8.3 arm-19.2"
export DEFAULT_COMPILER=cce-9.0
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
