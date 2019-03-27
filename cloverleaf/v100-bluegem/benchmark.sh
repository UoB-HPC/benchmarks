#!/bin/bash -i

DEFAULT_MODEL=omp-target
function usage
{
  echo
  echo "Usage: ./benchmark.sh build|run [MODEL]"
  echo
  echo "Valid models:"
  echo "  opencl"
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
SCRIPT=`readlink -f $0`
SCRIPT_DIR=`readlink -f $(dirname $SCRIPT)`
export BENCHMARK_EXE=clover_leaf

case "$MODEL" in
  opencl)
    COMPILER=gcc-6.1.0
    module load gcc/6.1.0
    module load cuda80/toolkit/8.0.44
    module load openmpi/gcc/64/1.8.1
    export MAKEFLAGS='-j16'
    export SRC_DIR=$PWD/CloverLeaf
    NVCC=`which nvcc`
    CUDA_PATH=`dirname $NVCC`/..
    CUDA_INCLUDE=$CUDA_PATH/include
    MAKE_OPTS='COMPILER=GNU USE_OPENCL=1 EXTRA_INC="-I $CUDA_INCLUDE -I $CUDA_INCLUDE/CL -L$CUDA_PATH/lib64" EXTRA_PATH="-I $CUDA_INCLUDE -I $CUDA_INCLUDE/CL -L$CUDA_PATH/lib64" \
         FLAGS_GNU="-std=c++11 -Wall -Wpedantic -g -Wno-unknown-pragmas -O3  -lm"'
    mkdir -p $SRC_DIR/obj $SRC_DIR/mpiobj
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
