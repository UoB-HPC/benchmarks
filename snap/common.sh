#!/bin/bash

set -u

function usage
{
    echo
    echo "Usage:"
    echo "  # Build the benchmark"
    echo "  ./benchmark.sh build [COMPILER]"
    echo
    echo "  # Run on a single node"
    echo "  ./benchmark.sh run node [COMPILER]"
    echo
    echo "  # Run on N nodes"
    echo "  ./benchmark.sh run scale-N [COMPILER]"
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
if [ "$ACTION" == "run" ]
then
    shift
    RUN_ARGS="$1"
fi
COMPILER="${2:-$DEFAULT_COMPILER}"
SCRIPT="`realpath $0`"
SCRIPT_DIR="`realpath $(dirname $SCRIPT)`"

export CONFIG="${ARCH}_${COMPILER}"
export SRC_DIR="$PWD/SNAP/src"
export CFG_DIR="$PWD/snap/${ARCH}/${COMPILER}"
export BENCHMARK_TEMPLATE=$SCRIPT_DIR/benchmark.in

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

    # Perform build
    rm -f "$SRC_DIR/$BENCHMARK_EXE" "$CFG_DIR/$BENCHMARK_EXE"
    if ! eval make -C $SRC_DIR -B $MAKE_OPTS
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

    mkdir -p "$CFG_DIR"
    mv "$SRC_DIR/$BENCHMARK_EXE" "$CFG_DIR/$BENCHMARK_EXE"

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$CFG_DIR/$BENCHMARK_EXE" ]
    then
        echo "Executable '$CFG_DIR/$BENCHMARK_EXE' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    cd "$CFG_DIR"

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

        # Calculate weak scaling factors for Y and Z dimensions
        i=1
        YSCALE=1
        ZSCALE=1
        while [ $i -lt $NODES ]
        do
            if [ $YSCALE -lt $ZSCALE ]
            then
                let YSCALE*=2
            else
                let ZSCALE*=2
            fi
            let i*=2
        done
        if [ $i -ne $NODES ]
        then
            echo "ERROR: Number of nodes must be a power of two for weak-scaling"
            exit 1
        fi
        export YSCALE
        export ZSCALE
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
        -N "snap_${RUN_ARGS}_${CONFIG}" \
        -V \
        "$PLATFORM_DIR/$JOBSCRIPT"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
