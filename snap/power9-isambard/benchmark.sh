#!/bin/bash

DEFAULT_COMPILER=gcc-8.1
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  gcc-8.1"
    echo "  xl-16.1"
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
export CONFIG="pwr9"_"$COMPILER"
export SRC_DIR=$PWD/SNAP/src
export RUN_DIR=$PWD/SNAP-$CONFIG


# Set up the environment
case "$COMPILER" in
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        module load openmpi/3.0.2/gcc8
        export BENCHMARK_EXE=gsnap
        MAKE_OPTS='TARGET=gsnap FFLAGS="-Ofast -mcpu=native -ffast-math -ffp-contract=fast -fopenmp"'
        ;;
    xl-16.1)
        module purge
        module load openmpi/4.0.0/xl-16
        export BENCHMARK_EXE=gsnap
        MAKE_OPTS='TARGET=gsnap FFLAGS="-O4 -qnoipa -qarch=auto -qtune=auto -qsmp=omp -qthreaded"'
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
    if ! "$SCRIPT_DIR/../fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    # Perform build
    rm -f $SRC_DIR/$BENCHMARK_EXE $RUN_DIR/$BENCHMARK_EXE
    make -C $SRC_DIR clean
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

    cd $RUN_DIR
    bash $SCRIPT_DIR/run_omp.sh
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
