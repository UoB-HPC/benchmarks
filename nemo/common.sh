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
    for compiler in $COMPILERS
    do
      echo "  $compiler"
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
SCRIPT="`realpath $0`"
export SCRIPT_DIR="`realpath $(dirname $SCRIPT)`"

export CONFIG="${ARCH}_${COMPILER}"
export SRC_DIR="$PWD/NEMOGCM"
export RUN_DIR="$SRC_DIR/cfgs/$CONFIG/EXP00"

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

    # Generate arch config file
    envsubst <"$SCRIPT_DIR/template.fcm" >"$SRC_DIR/arch/arch-$CONFIG.fcm"

    # Perform build
    if ! "$SRC_DIR/makenemo" -r GYRE_PISCES -m "$CONFIG" -n "$CONFIG" -j 1 del_key "key_iomput" add_key "key_nosignedzero"
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$RUN_DIR/nemo" ]
    then
        echo "Executable '$RUN_DIR/nemo' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    cd "$RUN_DIR"

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
        -N "nemo_${RUN_ARGS}_${CONFIG}" \
        -V \
        "$PLATFORM_DIR/$JOBSCRIPT"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
