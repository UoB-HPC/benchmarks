#!/bin/bash

set -u

function usage
{
    echo
    echo "Usage:"
    echo "  # Build the benchmark"
    echo "  ./benchmark.sh build [COMPILER] [BLAS-LIB] [FFT-LIB]"
    echo
    echo "  # Run on a single node"
    echo "  ./benchmark.sh run node [COMPILER] [BLAS-LIB] [FFT-LIB]"
    echo
    echo "  # Run on N nodes"
    echo "  ./benchmark.sh run scale-N [COMPILER] [BLAS-LIB] [FFT-LIB]"
    echo
    echo "Valid compilers:"
    for compiler in $COMPILERS
    do
      echo "  $compiler"
    done
    echo
    echo "Valid BLAS libraries:"
    for blaslib in $BLASLIBS
    do
      echo "  $blaslib"
    done
    echo
    echo "Valid FFT libraries:"
    for fftlib in $FFTLIBS
    do
      echo "  $fftlib"
    done
    echo
    echo "The default configuration is '$DEFAULT_COMPILER $DEFAULT_BLASLIB $DEFAULT_FFTLIB'."
    echo
}

# Process arguments
if [ $# -lt 1 ]
then
    usage
    exit 1
fi

ACTION="$1"
if [ "$ACTION" == "run" ]
then
    shift
    RUN_ARGS="$1"
fi
COMPILER="${2:-$DEFAULT_COMPILER}"
BLASLIB="${3:-$DEFAULT_BLASLIB}"
FFTLIB="${4:-$DEFAULT_FFTLIB}"
SCRIPT="`realpath $0`"
SCRIPT_DIR="`realpath $(dirname $SCRIPT)`"

export CONFIG="${ARCH}_${COMPILER}_${BLASLIB}_${FFTLIB}"
export CFG_DIR="$PWD/vasp/${ARCH}/${COMPILER}_${BLASLIB}_${FFTLIB}"
export SRC_DIR="$CFG_DIR/vasp.5.4.4"
export BENCHMARK_REPO="$PWD/vasp-test-suite"
export BENCHMARK_DIR="$CFG_DIR/vasp-test-suite"
export NODE_BENCHMARK=PdO/91
export SCALE_BENCHMARK=PdO/91/grow/run

# Set up the environment
setup_env

# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! "$SCRIPT_DIR/fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    # Unpack VASP source
    mkdir -p "$CFG_DIR"
    rm -rf "$SRC_DIR"
    tar xf vasp.5.4.4.tar.gz -C "$CFG_DIR"

    # Generate arch config file
    envsubst <"$SCRIPT_DIR/makefile.include.template" >"$SRC_DIR/makefile.include"

    # Perform build
    cd "$SRC_DIR"
    if ! make std gam
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$SRC_DIR/bin/vasp_std" ]
    then
        echo "Executable '$SRC_DIR/bin/vasp_std' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    cd "$CFG_DIR"

    if [ ! -d vasp-test-suite ]
    then
        git clone "$BENCHMARK_REPO"
    fi

    if [ "$RUN_ARGS" == node ]
    then
        NODES=1
        JOBSCRIPT=node.job
    elif [[ "$RUN_ARGS" == scale-* ]]
    then
        export NODES=${RUN_ARGS#scale-}
        if ! [[ "$NODES" =~ ^[0-9]+$ ]]
        then
            echo
            echo "Invalid node count for 'run scale-N' action"
            echo
            exit 1
        fi
        JOBSCRIPT=scale.job
    else
        echo
        echo "Invalid 'run' argument '$RUN_ARGS'"
        usage
        exit 1
    fi

    # Submit job
    mkdir -p "$RUN_ARGS"
    cd "$RUN_ARGS"
    qsub -l select=$NODES$PBS_RESOURCES \
        -o job.out \
        -N "vasp_${RUN_ARGS}_${CONFIG}" \
        -V \
        "$PLATFORM_DIR/$JOBSCRIPT"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
