#!/bin/bash

DEFAULT_MODEL=opencl
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
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`
export BENCHMARK_EXE=clover_leaf

case "$MODEL" in
  opencl)
    COMPILER=gcc-4.8.5
    module load opencl/gpu
    module load openmpi/gcc-4.8
    export MAKEFLAGS='-j16'
    export SRC_DIR=$PWD/CloverLeaf
    MAKE_OPTS='COMPILER=GNU USE_OPENCL=1 EXTRA_INC="-I $SCRIPT_DIR" EXTRA_PATH="-I $SCRIPT_DIR"'
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

  wget https://raw.githubusercontent.com/KhronosGroup/OpenCL-CLHPP/master/input_cl2.hpp
  mv input_cl2.hpp cl.hpp

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
