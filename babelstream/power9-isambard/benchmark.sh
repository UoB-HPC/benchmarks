#!/bin/bash

DEFAULT_COMPILER=xl-16.1
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  xl-16.1"
    echo "  gcc-8.1"
    echo "  pgi-18"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  kokkos"
    echo "  acc"
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

export CONFIG="pwr9"_"$COMPILER"_"$MODEL"
export BENCHMARK_EXE=stream-$CONFIG
export SRC_DIR=$SCRIPT_DIR/../BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
case "$COMPILER" in
    xl-16.1)
        MAKE_OPTS="COMPILER=XL TARGET=CPU"
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        MAKE_OPTS="COMPILER=GNU TARGET=CPU"
        ;;
    pgi-18)
        module purge
        module load pgi/18.10
        MAKE_OPTS="COMPILER=PGI TARGET=CPU"
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

    # Select Makefile to use
    case "$MODEL" in
      omp)
        MAKE_FILE="OpenMP.make"
        BINARY="omp-stream"
        ;;
      kokkos)
        module load kokkos/power9/gcc-8.1
        MAKE_FILE="Kokkos.make"
        BINARY="kokkos-stream"
        if [ "$COMPILER" != "gcc-8.1" ]
        then
          echo
          echo "Must use gcc-8.1 with Kokkos"
          echo
          stop
        fi
        ;;
      acc)
        MAKE_FILE="OpenACC.make"
        BINARY="acc-stream"
        MAKE_OPTS+=" TARGET=PWR9"
        if [ "$COMPILER" != "pgi-18" ]
        then
          echo
          echo "Must use pgi-18 with OpenACC"
          echo
          stop
        fi
        ;;
    esac

    if ! eval make -f $MAKE_FILE -C $SRC_DIR -B $MAKE_OPTS
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

    # Rename binary
    mv $SRC_DIR/$BINARY $BENCHMARK_EXE

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$BENCHMARK_EXE" ]
    then
        echo "Executable '$BENCHMARK_EXE' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    cd $RUN_DIR
    bash "$SCRIPT_DIR/run.sh"

else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
