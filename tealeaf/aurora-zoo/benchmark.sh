#!/bin/bash

set -e

DEFAULT_COMPILER=nec-2.1
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  nec-2.1"
    echo
    echo "Valid models:"
    echo "  mpi"
    echo "  omp"
    echo
    echo "The default configuration is '$DEFAULT_COMPILER $DEFAULT_MODEL'."
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
export MODEL=${3:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export BENCHMARK_EXE=tea_leaf
export CONFIG="aurora"_"$COMPILER"
export SRC_DIR=$PWD/TeaLeaf_ref
export RUN_DIR=$PWD/TeaLeaf-$CONFIG


# Set up the environment
case "$COMPILER" in
    nec-2.1)
        source /opt/nec/ve/mpi/2.0.0/bin64/necmpivars.sh
        export NMPI_F90=/opt/nec/ve/bin/nfort-2.1.1
        export NMPI_CC=/opt/nec/ve/bin/ncc-2.1.1
        MAKE_OPTS='MPI_COMPILER=mpinfort C_MPI_COMPILER=mpincc OPTIONS="-O4 -fopenmp" C_OPTIONS="-O4 -fopenmp"'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
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

    # Apply the patch
    #if ! eval patch --directory=$SRC_DIR --dry-run --forward --reverse < remove_io.patch
    #then
    #  patch --directory=$SRC_DIR --forward < remove_io.patch
    #fi

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

    cd "$RUN_DIR"
    bash "$SCRIPT_DIR"/run.sh
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
