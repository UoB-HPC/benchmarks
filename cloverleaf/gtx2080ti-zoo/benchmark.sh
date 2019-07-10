#!/bin/bash

DEFAULT_MODEL=omp-target
function usage
{
  echo
  echo "Usage: ./benchmark.sh build|run [MODEL]"
  echo
  echo "Valid models:"
  echo "  omp-target"
  echo "  kokkos"
  echo "  cuda"
  echo "  opencl"
  echo "  acc"
  echo
  echo "The default model is '$DEFAULT_MODEL'."
  echo
}

# Process arguments
if [ $# -lt 1 ]
then
  usage
  exit 1
fi

ACTION=$1
#COMPILER=${2:-$DEFAULT_COMPILER}
export MODEL=${2:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`
export BENCHMARK_EXE=clover_leaf

case "$MODEL" in
  omp-target)
    COMPILER=clang-9
    module load llvm/trunk
    module load openmpi/3.0.3-gcc-4.8.5
    module load cuda/10.1
    export OMPI_MPICC=clang
    export OMPI_FC=gfortran
    export SRC_DIR="$PWD/CloverLeaf-OpenMP4"
    export MAKEFLAGS='-j36'
    MAKE_OPTS='\
      COMPILER=CLANG MPI_C=mpicc MPI_F90=mpif90 \
      CFLAGS="-O3 -DOFFLOAD -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_75 -lrt -lm -lgfortran -lmpi_usempi -lmpi_mpifh" \
      FLAGS="-O3 -DOFFLOAD -lgfortran -lmpi_usempi -lmpi_mpifh"'
    ;;
  kokkos)
    COMPILER=gcc-8.3.0
    module load kokkos/2.8.00/volta72
    module load openmpi/4.0.1/gcc-8.3
    export SRC_DIR=$PWD/cloverleaf_kokkos
    export MAKEFLAGS='-j16'
    MAKE_OPTS='-f Makefile.gpu'
    ;;
  cuda)
    COMPILER=nvcc
    module load cuda/10.1
    export MAKEFLAGS='-j16'
    export SRC_DIR=$PWD/CloverLeaf
    MAKE_OPTS='COMPILER=GNU USE_CUDA=1'
    ;;
  opencl)
    COMPILER=gcc-4.8.5
    module load cuda/10.1
    module load openmpi/3.0.3-gcc-4.8.5
    export MAKEFLAGS='-j16'
    export SRC_DIR=$PWD/CloverLeaf
    MAKE_OPTS='COMPILER=GNU USE_OPENCL=1 \
        EXTRA_INC="-I/usr/local/cuda-10.1/targets/x86_64-linux/include/CL/" \
        EXTRA_PATH="-I/usr/local/cuda-10.1/targets/x86_64-linux/include/CL/"'
    ;;
  acc)
    COMPILER=pgi-18.10
    module load openmpi/2.1.2-pgi-18.10
    module load pgi/18.10
    module load cuda/10.1
    export SRC_DIR=$PWD/CloverLeaf-OpenACC
    export OMPI_CC=pgcc
    export OMPI_FC=pgfortran
    MAKE_OPTS='COMPILER=PGI C_MPI_COMPILER=mpicc MPI_F90=mpif90 \
        OPTIONS="-ta=tesla:cc70 -L/opt/local-modules/pgi/linux86-64/18.10/lib/ -Wl,-rpath,/opt/local-modules/pgi/linux86-64/18.10/lib/ -lpgm" \
        C_OPTIONS="-ta=tesla:cc70 -L/opt/local-modules/pgi/linux86-64/18.10/lib/ -Wl,-rpath,/opt/local-modules/pgi/linux86-64/18.10/lib/ -lpgm"'
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'"
    usage
    exit 1
    ;;
esac


export CONFIG="${COMPILER}_${MODEL}"
export RUN_DIR=$PWD/$CONFIG

# Handle actions
if [ "$ACTION" == "build" ]
then
  # Fetch source code
  if [ ! -e CloverLeaf/src/cudadefs.h ]; then
      if ! eval ../fetch.sh $MODEL
      then
          echo
          echo "Failed to fetch source code."
          echo
          exit 1
      fi
  fi

  mkdir -p $SRC_DIR/obj $SRC_DIR/mpiobj

  # Perform build
  rm -f $SRC_DIR/$BENCHMARK_EXE $RUN_DIR/$BENCHMARK_EXE
  if ! eval make -C $SRC_DIR -B $MAKE_OPTS
  then
    echo
    echo "Build failed."
    echo
    exit 1
  fi

  mkdir -p $RUN_DIR
  mv $SRC_DIR/$BENCHMARK_EXE $RUN_DIR

elif [ "$ACTION" == "run" ]
then
  if [ ! -x "$RUN_DIR/$BENCHMARK_EXE" ]
  then
    echo "Executable '$RUN_DIR/$BENCHMARK_EXE' not found."
    echo "Use the 'build' action first."
    exit 1
  fi

  bash $SCRIPT_DIR/run.sh &
else
  echo
  echo "Invalid action (use 'build' or 'run')."
  echo
  exit 1
fi
