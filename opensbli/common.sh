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
export COMPILER="${2:-$DEFAULT_COMPILER}"
SCRIPT="`realpath $0`"
SCRIPT_DIR="`realpath $(dirname $SCRIPT)`"

export CONFIG="${ARCH}_${COMPILER}"
export CFG_DIR="$PWD/opensbli/${ARCH}/${COMPILER}"
export SRC_DIR="$CFG_DIR/OpenSBLI"
export OPS_INSTALL_PATH="$SRC_DIR/OPS/ops"
export BENCHMARK_EXE="$SRC_DIR/Benchmark/OpenSBLI_mpi"

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

    mkdir -p "$CFG_DIR"

    # Unpack OpenSBLI benchmark source to per-config directory
    rm -rf "$CFG_DIR/OpenSBLI"
    unzip OpenSBLI_ARCHER_bench.zip -d "$CFG_DIR"

    # Fix a buffer overrun bug in the benchmark code
    sed -i 's/char type_of_simulation\[2\], HDF5op\[4\];/char type_of_simulation[3], HDF5op[6];/' \
        "$CFG_DIR/OpenSBLI/Benchmark/OpenSBLI_ops.cpp"

    # Build OPS
    if ! eval make -C "$OPS_INSTALL_PATH/c" -B core $OPS_MAKE_OPTS
    then
        echo
        echo "OPS build failed."
        echo
        exit 1
    fi
    if ! eval make -C "$OPS_INSTALL_PATH/c" -B mpi $OPS_MAKE_OPTS
    then
        echo
        echo "OPS build failed."
        echo
        exit 1
    fi

    # Build the benchmark
    if ! eval make -C "$SRC_DIR/Benchmark" -B OpenSBLI_mpi $SBLI_MAKE_OPTS
    then
        echo
        echo "OpenSBLI build failed."
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
    else
        echo
        echo "Invalid 'run' argument '$RUN_ARGS'"
        usage
        exit 1
    fi

    # Some systems use a different shell for jobs, breaking exported functions
    [ "${SYSTEM:-}" = catalyst ] && unset -f setup_env

    # Submit job
    mkdir -p $RUN_ARGS
    cd $RUN_ARGS
    qsub -l select=$NODES$PBS_RESOURCES \
        -o job.out \
        -N "opensbli_${RUN_ARGS}_${CONFIG}" \
        -V \
        "$PLATFORM_DIR/$JOBSCRIPT"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
