#!/bin/bash

DEFAULT_COMPILER=gcc-8.1
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

export CONFIG="tx2"_"$COMPILER"
export BENCHMARK_EXE=stream-$CONFIG
export SRC=$SCRIPT_DIR/../stream.c


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.0
        CC=cc
        FLAGS=""
        export OMP_PROC_BIND=true
        ;;
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        CC=gcc
        FLAGS="-std=gnu99 -fopenmp -Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99"
        export OMP_PROC_BIND=spread
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        CC=gcc
        FLAGS="-std=gnu99 -fopenmp -Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99"
        export OMP_PROC_BIND=spread
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        CC=armclang
        FLAGS="-std=gnu99 -fopenmp -Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99"
        export OMP_PROC_BIND=true
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

    # Best performance observed when only running 16 cores per socket.
    export OMP_NUM_THREADS=32
    ./$BENCHMARK_EXE
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
