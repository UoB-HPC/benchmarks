#!/bin/bash

DEFAULT_MODEL=cuda
function usage
{
  echo
  echo "Usage: ./benchmark.sh build|run [MODEL]"
  echo
  echo "Valid models:"
  echo "  kokkos"
  echo
  echo "The default configuration is '$DEFAULT_COMPILER'."
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
MODEL=${2:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

case "$MODEL" in
  kokkos)
    module load kokkos/turing
    module load openmpi/3.0.3-gcc-4.8.5
    module load
    export MAKEFLAGS='-j16'
    export SRC_DIR=$PWD/CloverLeaf
    export BENCHMARK_EXE=clover_leaf
    MAKE_OPTS='COMPILER=GNU USE_KOKKOS=gpu KOKKOS_PATH=$KOKKOS_PATH fast -j16'
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'"
    usage
    exit 1
    ;;
esac


export CONFIG="$MODEL"
export RUN_DIR=$PWD/$CONFIG

# Handle actions
if [ "$ACTION" == "build" ]
then
  # Fetch source code
  if ! "$SCRIPT_DIR/../fetch.sh" $MODEL
  then
    echo
    echo "Failed to fetch source code."
    echo
    exit 1
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

  bash $SCRIPT_DIR/run.job &> CloverLeaf-$CONFIG.out
else
  echo
  echo "Invalid action (use 'build' or 'run')."
  echo
  exit 1
fi
