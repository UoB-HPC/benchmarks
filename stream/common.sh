#!/bin/bash

set -u

function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    for COMPILER in $COMPILERS
    do
      echo "  $COMPILER"
    done
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

ACTION="$1"
COMPILER="${2:-$DEFAULT_COMPILER}"
SCRIPT="`realpath $0`"
SCRIPT_DIR="`realpath $(dirname $SCRIPT)`"
SRC="$SCRIPT_DIR/stream.c"

export CONFIG="${ARCH}_${COMPILER}"
export BENCHMARK_EXE="stream-$CONFIG"

# Set up the environment
setup_env

# Handle actions
if [ "$ACTION" == "build" ]
then
    # Perform build
    rm -f "$BENCHMARK_EXE"
    if ! $CC $FLAGS "$SRC" -o "$BENCHMARK_EXE"
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$BENCHMARK_EXE" ]
    then
        echo "Executable '$BENCHMARK_EXE' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    qsub -o "stream-$CONFIG.out" \
         -N stream \
         -V \
         "$PLATFORM_DIR/run.job"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
