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

export BENCHMARK_PLATFORM=bdw-swan
export BENCHMARK_EXE=clover_leaf
export SRC_DIR=$PWD/CloverLeaf_ref
export RUN_DIR=$PWD/CloverLeaf-$BENCHMARK_PLATFORM-$COMPILER

# Fetch source code if necessary
if [ ! -r "$SRC_DIR/clover.f90" ]
then
    if ! "$SCRIPT_DIR/../fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi
fi


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=broadwell -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=broadwell -funroll-loops"'
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_INTEL="-O3 -no-prec-div -xCORE-AVX2"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xCORE-AVX2"'
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
    qsub $SCRIPT_DIR/run.job \
        -o CloverLeaf-$BENCHMARK_PLATFORM-$COMPILER.out \
        -N cloverleaf \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
