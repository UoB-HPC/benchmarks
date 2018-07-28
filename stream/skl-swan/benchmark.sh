#!/bin/bash

DEFAULT_COMPILER=intel-2018
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.3"
    echo "  intel-2018"
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

export CONFIG="skl"_"$COMPILER"
export BENCHMARK_EXE=stream-$CONFIG
export SRC=$SCRIPT_DIR/../stream.c


# Set up the environment
module swap craype-{broadwell,x86-skylake}
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        CC=cc
        FLAGS=""
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        CC=gcc
        FLAGS="-fopenmp -Ofast -ffast-math -ffp-contract=fast -march=skylake-avx512"
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        CC=icc
        FLAGS="-qopenmp -Ofast -xCORE-AVX512 -qopt-streaming-stores=always"
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

    qsub $SCRIPT_DIR/run.job \
        -d $PWD \
        -o stream-$CONFIG.out \
        -N stream \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
