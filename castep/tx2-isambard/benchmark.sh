#!/bin/bash

function setup_env()
{
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-9.0)
          module load cdt/19.08
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/9.0.1
          LIBSCI_COMP="cray"
          ;;
      *)
          echo
          echo "Invalid compiler '$COMPILER'."
          usage
          exit 1
          ;;
  esac

  case "$BLASLIB" in
      cray-libsci-19.06.1)
          module swap cray-libsci cray-libsci/19.06.1
          # TODO ???
          # Make sure libsci gets linked before ArmPL
          #export LLIBS="$LLIBS -lsci_${LIBSCI_COMP}_mp -lsci_${LIBSCI_COMP}_mpi_mp"
          ;;
      *)
          echo
          echo "Invalid BLAS library '$BLASLIB'."
          usage
          exit 1
          ;;
  esac
  case "$FFTLIB" in
      cray-fftw-3.3.8)
          module load cray-fftw/3.3.8.2 
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
export COMPILERS="cce-9.0"
export BLASLIBS="cray-libsci-19.06.1"
export FFTLIBS="cray-fftw-3.3.8"
export DEFAULT_COMPILER=cce-9.0
export DEFAULT_BLASLIB=cray-libsci-19.06.1
export DEFAULT_FFTLIB=cray-fftw-3.3.8
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
