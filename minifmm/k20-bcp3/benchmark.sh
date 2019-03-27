#!/bin/bash

DEFAULT_MODEL=cuda
function usage
{
  echo
  echo "Usage: ./benchmark.sh build|run [MODEL]"
  echo
  echo "Valid models:"
  echo "  cuda"
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
SCRIPT=`readlink -f $0`
SCRIPT_DIR=`readlink -f $(dirname $SCRIPT)`

export SRC_DIR="$PWD/minifmm/"

case "$MODEL" in
  cuda)
    module unload languages/gcc-7.1.0
    module load languages/gcc-4.8.4
    module load cuda/toolkit/7.5.18
    export COMPILER=GNU
    export BENCHMARK_EXE="fmm.cuda"
    MAKE_OPTS='\
      COMPILER=GNU \
      MODEL="cuda" \
      ARCH="sm_35"'
    ;;
  kokkos)
    module use /newhome/pa13269/modules/modulefiles
    module unload languages/gcc-7.1.0
    module load languages/gcc-4.8.4
    module load cuda/toolkit/7.5.18
    module load kokkos
    export COMPILER=NVCC
    export BENCHMARK_EXE="fmm.kokkos"
    MAKE_OPTS='\
      MODEL="kokkos" \
      ARCH="sm_35"'
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'"
    usage
    exit 1
    ;;

    # Set up the environment
esac


export CONFIG="k20"_"$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/minifmm-$CONFIG

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

  export RUN_ARGS="-i $SRC_DIR/inputs/large.in"

  qsub \
    -o minifmm-$CONFIG.out \
    -N minifmm \
    -V \
    $SCRIPT_DIR/run.job 
else
  echo
  echo "Invalid action (use 'build' or 'run')."
  echo
  exit 1
fi
