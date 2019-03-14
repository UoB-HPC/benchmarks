#!/bin/bash

DEFAULT_COMPILER=intel-2018
DEFAULT_MODEL=omp
function usage
{
  echo
  echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
  echo
  echo "Valid compilers:"
  echo "  clang"
  echo "  nvcc"
  echo
  echo "Valid models:"
  echo "  omp-target"
  echo "  kokkos"
  echo "  cuda"
  echo
  echo "The default configuration is '$DEFAULT_COMPILER'."
  echo "The default programming model is '$DEFAULT_MODEL'."
  echo
}

# Process arguments
if [ $# -lt 1 ]
then
  usage
  exit 1
fi

ACTION=$1
COMPILER=${2:-$DEFAULT_COMPILER}
MODEL=${3:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export CONFIG="gtx2080ti"_"$COMPILER"_"$MODEL"
export BENCHMARK_EXE=stream-$CONFIG
export SRC_DIR=$SCRIPT_DIR/BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
module load cuda/10.1
case "$COMPILER" in
  clang)
    module load llvm/trunk
    MAKE_OPTS='\
      COMPILER=CLANG \
      TARGET=NVIDIA \
      EXTRA_FLAGS="-Xopenmp-target -march=sm_75"'
    ;;
  nvcc)
    ;;
  gcc-4.8)
    MAKE_OPTS='\
      COMPILER=GNU'
    ;;
  pgi-18.10)
    MAKE_OPTS='\
      COMPILER=PGI'
    ;;
  *)
    echo
    echo "Invalid compiler '$COMPILER'."
    usage
    exit 1
    ;;
esac

case "$MODEL" in
  omp-target)
    MAKE_FILE="OpenMP.make"
    BINARY="omp-stream"
    ;;
  cuda)
    MAKE_FILE="CUDA.make"
    BINARY="cuda-stream"
    MAKE_OPTS='\
      EXTRA_FLAGS="-arch=sm_75"'
    ;;
  kokkos)
    module load kokkos/turing
    MAKE_FILE="Kokkos.make"
    BINARY="kokkos-stream"
    MAKE_OPTS="$MAKE_OPTS TARGET=GPU"
    if [ "$COMPILER" != "nvcc" ]; then
      echo
      echo " Must use NVCC with Kokkos module"
      echo
      exit 1
    fi
    ;;
  ocl)
    MAKE_FILE="OpenCL.make"
    BINARY="ocl-stream"
    MAKE_OPTS="$MAKE_OPTS TARGET=GPU"
    ;;
  acc)
    MAKE_FILE="OpenACC.make"
    BINARY="acc-stream"
    MAKE_OPTS="$MAKE_OPTS TARGET=VOLTA"
    ;;
esac


# Handle actions
if [ "$ACTION" == "build" ]
then
  # Fetch source code
  if ! "$SCRIPT_DIR/../fetch.sh"
  then
    echo
    echo "Failed to fetch source code."
    echo
    exit 1
  fi


  # Perform build
  if ! eval make -f $MAKE_FILE -C $SRC_DIR -B $MAKE_OPTS
  then
    echo
    echo "Build failed."
    echo
    exit 1
  fi

  mkdir -p $RUN_DIR
  # Rename binary
  mv $SRC_DIR/$BINARY $RUN_DIR/$BENCHMARK_EXE

elif [ "$ACTION" == "run" ]
then
  if [ ! -x "$RUN_DIR/$BENCHMARK_EXE" ]
  then
    echo "Executable '$RUN_DIR/$BENCHMARK_EXE' not found."
    echo "Use the 'build' action first."
    exit 1
  fi

  bash run.job
else
  echo
  echo "Invalid action (use 'build' or 'run')."
  echo
  exit 1
fi
