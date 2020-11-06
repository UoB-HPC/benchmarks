#!/bin/bash

function setup_env()
{
  module restore PrgEnv-cray
  module use /lustre/projects/bristol/modules-a64fx/modulefiles/
  case "$COMPILER" in
      cce-10.0)
          module unload cce-sve
          module load cce/10.0.3
          module load craype-arm-nsp1
          module load cray-mvapich2_noslurm_nogpu/2.3.4
          module load cray-hdf5-parallel/1.12.0.2
          export HDF5_INSTALL_PATH="$HDF5_DIR"
          export OPS_COMPILER=cray
          OPS_MAKE_OPTS='MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffp-contract=fast"'
          SBLI_MAKE_OPTS='MPICPP=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -ffp-contract=fast"'
          ;;
      cce-sve-10.0)
          module swap cce-sve cce-sve/10.0.1
          module load craype-arm-nsp1
          module load cray-mvapich2_noslurm_nogpu/2.3.4
          module load cray-hdf5-parallel/1.12.0.2
          export HDF5_INSTALL_PATH="$HDF5_DIR"
          export OPS_COMPILER=cray
        #   OPS_MAKE_OPTS='MPICC=cc MPICXX=CC CXXFLAGS="-O3"'
          OPS_MAKE_OPTS=''
          SBLI_MAKE_OPTS='MPICPP=CC CCFLAGS="-O3"'
          ;;
      gcc-11.0)
          module load gcc/11-20201025
          module load openmpi/4.0.4/gcc-11.0
          module load hdf5/1.12.0/gcc-11
          export HDF5_INSTALL_PATH="/lustre/projects/bristol/modules-a64fx/hdf5/1.12.0/gcc-11"
          export OPS_COMPILER=gnu
          OPS_MAKE_OPTS='MPICPP=mpiCC MPICC=mpicc MPICXX=mpiCC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=a64fx -ffp-contract=fast"'
          SBLI_MAKE_OPTS='MPICPP=mpiCC MPICC=mpicc MPICXX=mpiCC CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=a64fx -ffp-contract=fast"'
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
export ARCH="a64fx"
export SYSTEM="isambard"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="cce-10.0 cce-sve-10.0 gcc-8.3 gcc-11.0 arm-19.2"
export DEFAULT_COMPILER=cce-sve-10.0
export PBS_RESOURCES=":ncpus=48"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
