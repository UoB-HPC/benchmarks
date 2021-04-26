#!/bin/bash

function setup_env()
{
  if ! grep -q bristol/modules-a64fx/ <<<"$MODULEPATH"; then
    module use /lustre/projects/bristol/modules-a64fx/modulefiles
  fi
  if ! grep -q lustre/software/aarch64/ <<<"$MODULEPATH"; then
    module use /lustre/software/aarch64/modulefiles
  fi

  case "$COMPILER" in
      arm-21.0)
          module load tools/arm-compiler-a64fx/21.0
          module load openmpi/4.1.0/arm-21.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops -cpp -ffree-line-length-none"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          ;;
      cce-10.0)
          module unload cce cce-sve
          module unload craype-arm-nsp1
          module load cce/10.0.3
          module load cray-mvapich2_noslurm_nogpu
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_CRAY="-em -ra -h acc_model=fast_addr:no_deep_copy:auto_async_all -homp"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_CRAY="-Ofast -fopenmp -funroll-loops"'
          ;;
      cce-sve-10.0)
          module unload cce cce-sve
          module load cce-sve/10.0.1
          module load cray-mvapich2_noslurm_nogpu
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_CRAY="-em -ra -h acc_model=fast_addr:no_deep_copy:auto_async_all -homp"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_CRAY="-O3 -homp"'
          ;;
      fcc-4.3)
          module load fujitsu-compiler/4.3.1
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpifrt C_MPI_COMPILER=mpifcc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Kfast,assume=memory_bandwidth,simd=3"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Kfast,assume=memory_bandwidth,simd=3"'
          ;;
      gcc-10.3)
          module unload cce cce-sve
          module swap gcc gcc/10.3.0
          module load openmpi/4.1.0/gcc-11.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=a64fx -funroll-loops -cpp -ffree-line-length-none -fallow-argument-mismatch"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=a64fx -funroll-loops"'
          ;;
      gcc-11.0)
          module unload cce cce-sve
          module swap gcc gcc/11-20210321
          module load openmpi/4.1.0/gcc-11.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpif90 C_MPI_COMPILER=mpicc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=a64fx -funroll-loops -cpp -ffree-line-length-none -fallow-argument-mismatch"'
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
export COMPILERS="arm-21.0 cce-10.0 cce-sve-10.0 fcc-4.3 gcc-10.3 gcc-11.0"
export DEFAULT_COMPILER="fcc-4.3"
export PBS_RESOURCES=":ncpus=48"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
