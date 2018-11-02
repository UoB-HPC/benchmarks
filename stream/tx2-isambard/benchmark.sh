#!/bin/bash

DEFAULT_COMPILER=gcc-8.2
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-8.2"
    echo "  arm-19.0"
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

ACTION=$1
COMPILER=${2:-$DEFAULT_COMPILER}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export CONFIG="tx2"_"$COMPILER"
export BENCHMARK_EXE=stream-$CONFIG
export SRC=$SCRIPT_DIR/../stream.c


# Set up the environment
module unload `module -t list 2>&1 | grep PrgEnv`
case "$COMPILER" in
    cce-8.7)
        module load PrgEnv-cray
        module swap cce cce/8.7.9
        CC=cc
        FLAGS=""
        ;;
    gcc-8.2)
        module load PrgEnv-gnu
        module swap gcc gcc/8.2.0
        CC=gcc
        FLAGS="-std=gnu99 -fopenmp -Ofast -mcpu=native"
        ;;
    arm-19.0)
        module load PrgEnv-allinea
        module swap allinea allinea/19.0.0.1
        CC=armclang
        # NOTE: This version has a performance regression with -ffast-math
        FLAGS="-std=gnu99 -fopenmp -O3 -ffp-contract=fast -mcpu=native"
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
    # Perform build
    rm -f $BENCHMARK_EXE
    if ! $CC $FLAGS $SRC -o $BENCHMARK_EXE
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

    qsub -o stream-$CONFIG.out \
         -N stream \
         -V \
         $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
