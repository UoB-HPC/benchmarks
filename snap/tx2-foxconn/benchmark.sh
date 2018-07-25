#!/bin/bash

DEFAULT_COMPILER=cce-8.7
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.2"
    echo "  gcc-8.1"
    echo "  arm-18.3"
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

export BENCHMARK_TEMPLATE=$SCRIPT_DIR/../benchmark.in
export CONFIG="tx2"_"$COMPILER"
export SRC_DIR=$PWD/SNAP/src
export RUN_DIR=$PWD/SNAP-$CONFIG


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.0
        export BENCHMARK_EXE=csnap
        MAKE_OPTS='TARGET=csnap FORTRAN=ftn FFLAGS=-hfp3 PP=cpp'
        ;;
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        module load openmpi/3.0.0/gcc-7.2
        export BENCHMARK_EXE=gsnap
        MAKE_OPTS='TARGET=gsnap FFLAGS="-Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast -fopenmp"'
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        module load openmpi/3.0.0/gcc-8.1
        export BENCHMARK_EXE=gsnap
        MAKE_OPTS='TARGET=gsnap FFLAGS="-Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast -fopenmp"'
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        module load openmpi/3.0.0/arm-18.3
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
    bash $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
