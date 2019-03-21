#!/bin/bash

set -eu

DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [MODEL]"
    echo
    echo "Valid models:"
    echo "  omp-target"
    echo "  cuda"
    echo
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
MODEL=${2:-$DEFAULT_MODEL}
SCRIPT=`basename $0`
SCRIPT_DIR=`dirname $0`
export BENCHMARK_EXE=clover_leaf

module use /lustre/projects/bristol/modules-power/modulefiles
module purge
case "$MODEL" in
    omp-target)
        echo "OMP target not implemented yet"
        exit 99
        ;;
    cuda)
        module load cuda/10.0
        module load mpi/openmpi-ppc64le
        export SRC_DIR="$PWD/CloverLeaf_CUDA"
        MAKE_OPTS="-j20 COMPILER=GNU NV_ARCH=VOLTA CODEGEN_VOLTA='-gencode arch=compute_70,code=sm_70'"
        ;;
    *)
        echo
        echo "Invalid model '$MODEL'."
        usage
        exit 1
        ;;
esac

export CONFIG="v100_$MODEL"
export RUN_DIR="$PWD/CloverLeaf-$CONFIG"

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
    rm -f "$SRC_DIR/$BENCHMARK_EXE" "$RUN_DIR/$BENCHMARK_EXE"
    make -C "$SRC_DIR" clean
    if ! eval make -C "$SRC_DIR" -B "$MAKE_OPTS"
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

    bash "$SCRIPT_DIR/run.sh"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
