#!/bin/bash

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-9.0)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/9.0.1
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_CRAY="-em -ra -h acc_model=fast_addr:no_deep_copy:auto_async_all -homp"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_CRAY="-Ofast -funroll-loops -fopenmp"'
          ;;
      cce-10.0)
          module load cdt/20.12
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/10.0.1
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_CRAY="-em -ra -h acc_model=fast_addr:no_deep_copy:auto_async_all -homp"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_CRAY="-Ofast -funroll-loops -fopenmp"'
          ;;
      cce-11.0)
          module load cdt/20.12
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/11.0.1
          MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_CRAY="-em -ra -h acc_model=fast_addr:no_deep_copy:auto_async_all -homp"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_CRAY="-Ofast -funroll-loops -fopenmp"'
          ;;
      gcc-8.3)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.3.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          ;;
      gcc-10.1)
          module load cdt/20.12
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/10.1.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops -fallow-argument-mismatch"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          ;;
      arm-19.2)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/19.2.0.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
          ;;
      arm-20.0)
          module swap $PRGENV PrgEnv-allinea
          module swap allinea allinea/20.0.0.0
          MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
          MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -mcpu=native -funroll-loops"'
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
export COMPILERS="cce-9.0 gcc-8.3 arm-19.2"
export DEFAULT_COMPILER=cce-9.0
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
