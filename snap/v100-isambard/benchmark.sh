#!/bin/bash

DEFAULT_COMPILER=gcc-4.8
DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  gcc-4.8"
    echo
    echo "Valid models:"
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

export BENCHMARK_TEMPLATE=$SCRIPT_DIR/../benchmark.in
export CONFIG="v100"_"$COMPILER"_"$MODEL"


export RUN_DIR=$PWD/SNAP-$CONFIG


# Set up the environment
export BENCHMARK_EXE=snap
module load cuda/10.0
case "$COMPILER" in
    gcc-4.8)
        MAKE_OPTS='COMPILER=GNU'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

# Set options based on model
case "$MODEL" in
  cuda)
    export SRC_DIR=$PWD/SNAP_MPI_CUDA/src
    ;;
  omp)
    export SRC_DIR=$PWD/SNAP/src
    ;;
esac

# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! eval "$SCRIPT_DIR/../fetch.sh $MODEL"
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

    if ! eval bash run.job > $CONFIG.out
    then
        echo
        echo "Run failed."
        echo
        exit 1
    fi

else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
