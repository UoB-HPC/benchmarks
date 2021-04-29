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
          MAKE_OPTS='COMPILER=ARM ARCH=a64fx MODEL=omp-task'
          ;;
      cce-10.0)
          module unload cce cce-sve
          module unload craype-arm-nsp1
          module load cce/10.0.3
          MAKE_OPTS='COMPILER=CRAY ARCH=native MODEL=omp-task'
          ;;
      fcc-4.3)
          module load fujitsu-compiler/4.3.1
          MAKE_OPTS='COMPILER=GNU CC_GNU="FCC -Nclang" CFLAGS_GNU="-mcpu=a64fx -Ofast -fopenmp" MODEL=omp-task'
          ;;
      gcc-10.3)
          module unload cce cce-sve
          module swap gcc gcc/10.3.0
          MAKE_OPTS='COMPILER=GNU ARCH=a64fx MODEL=omp-task'
          ;;
      gcc-11.0)
          module unload cce cce-sve
          module swap gcc gcc/11-20210321
          MAKE_OPTS='COMPILER=GNU ARCH=a64fx MODEL=omp-task'
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
export COMPILERS="arm-21.0 cce-10.0 fcc-4.3 gcc-10.3 gcc-11.0"
export DEFAULT_COMPILER="gcc-11.0"
export PBS_RESOURCES=":ncpus=48"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
