#!/bin/bash

DEFAULT_COMPILER=cce-8.7
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-8.2"
    echo
    echo "Valid models:"
    echo "  omp"
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
export CONFIG="tx2"_"$COMPILER"_"$MODEL"


export RUN_DIR=$PWD/SNAP-$CONFIG


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.7
        export BENCHMARK_EXE=csnap
        MAKE_OPTS='TARGET=csnap FORTRAN=ftn FFLAGS=-hfp3 PP=cpp'
        ;;
    gcc-8.2)
        module swap PrgEnv-cray PrgEnv-gnu
        module swap gcc gcc/8.2.0
        export BENCHMARK_EXE=gsnap
        MAKE_OPTS='TARGET=gsnap FFLAGS="-Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast -fopenmp"'
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

    qsub $SCRIPT_DIR/run.job \
        -o snap-$CONFIG.out \
        -N snap \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
