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
    echo "  kokkos"
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

export CONFIG="p100"_"$COMPILER"_"$MODEL"
export BENCHMARK_EXE=stream-$CONFIG
export SRC_DIR=$SCRIPT_DIR/../BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
module swap craype-{mic-knl,broadwell}
module load craype-accel-nvidia60
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.6.4
        MAKE_OPTS="COMPILER=CRAY TARGET=NVIDIA"
        ;;
    gcc-8.2)
        module swap PrgEnv-cray PrgEnv-gnu
        module swap gcc gcc/8.2.0
        MAKE_OPTS="COMPILER=GNU TARGET=CPU"
        export OMP_PROC_BIND=spread
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
        module load kokkos/2.8.00
        MAKE_FILE="Kokkos.make"
        BINARY="kokkos-stream"
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

    qsub \
        -o BabelStream-$CONFIG.out \
        -N babelstream \
        -V \
        $SCRIPT_DIR/run.job \

else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
