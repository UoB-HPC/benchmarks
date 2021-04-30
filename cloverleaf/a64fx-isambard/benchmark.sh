#!/bin/bash

function setup_env()
{
  case "$COMPILER" in
      arm-21.0)
          module load tools/arm-compiler-a64fx/21.0
          module load openmpi/4.1.0/arm-21.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=a64fx -funroll-loops -ffp-contract=fast -fsimdmath"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=a64fx -funroll-loops -ffp-contract=fast -fsimdmath"'
          ;;
      cce-10.0)
          module unload cce-sve
          module swap cce cce/10.0.3
          module swap craype-arm-nsp1 craype-arm-thunderx2
          module load cray-mvapich2_noslurm_nogpu/2.3.4
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_CRAY="-em -ra -h acc_model=fast_addr:no_deep_copy:auto_async_all -homp"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_CRAY="-Ofast -funroll-loops -fopenmp"'
          ;;
      cce-sve-10.0)
          module unload cce
          module swap cce-sve cce-sve/10.0.1
          module load craype-arm-nsp1
          module load cray-mvapich2_noslurm_nogpu/2.3.4
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_CRAY="-em -ra -h acc_model=fast_addr:no_deep_copy:auto_async_all -homp"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_CRAY="-em -hlist=a -homp"'
          ;;
      fcc-4.3)
          module load fujitsu-compiler/4.3.1
          module load openmpi/4.1.0/fcc-4.3-clang
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Kfast,A64FX,simd=2,assume=memory_bandwidth"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Kfast,A64FX,simd=2,assume=memory_bandwidth"'
          MAKE_OPTS=$MAKE_OPTS' OMP_GNU=-Kopenmp'
          ;;
      gcc-8.1)
          module load gcc/8.1.0
          module load openmpi/4.0.4/gcc-8.1
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -march=armv8.3-a+sve -funroll-loops"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -march=armv8.3-a+sve -funroll-loops"'
          ;;
      gcc-11.0)
          module load gcc/11.1.0
          module load openmpi/4.1.0/gcc-11.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=a64fx -funroll-loops"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=a64fx -funroll-loops"'
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
export COMPILERS="cce-10.0 cce-sve-10.0 fcc-4.3 gcc-8.1 gcc-11.0"
export DEFAULT_COMPILER="gcc-11.0"
export PBS_RESOURCES=":ncpus=48"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
