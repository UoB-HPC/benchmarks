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
    echo "  intel-2019"
    echo "  pgi-18"
    echo
    echo "Valid models:"
    echo "  acc"
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
export COMPILER=${2:-$DEFAULT_COMPILER}
MODEL=${3:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export CONFIG="naples"_"$COMPILER"_"$MODEL"
export BENCHMARK_EXE=stream-$CONFIG
export SRC_DIR=$SCRIPT_DIR/BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
#module use /opt/modules/modulefiles
module use /mnt/shared/software/modulefiles
case "$COMPILER" in
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        MAKE_OPTS="COMPILER=GNU TARGET=CPU"
        ;;
    intel-2019)
        module purge
        module load intel/compiler/2019.2
        MAKE_OPTS="COMPILER=INTEL TARGET=CPU"
        ;;
    pgi-18)
        module purge
        module load pgi/18.10
        MAKE_OPTS="COMPILER=PGI TARGET=ZEN TARGET_FLAGS_ZEN='-ta=multicore -tp=zen'"
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

    # Fetch source code
    if ! "$SCRIPT_DIR/../fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    # Select Makefile to use
    case "$MODEL" in
        acc)
            if [ "$COMPILER" =~ pgi ]]; then
                echo "OpenACC not supported with compiler $COMPILER"
                exit 1
            fi

            MAKE_FILE="OpenACC.make"
            BINARY="acc-stream"
            ;;
        omp)
            MAKE_FILE="OpenMP.make"
            BINARY="omp-stream"
            ;;
        kokkos)
            MAKE_FILE="Kokkos.make"
            BINARY="kokkos-stream"
            case "$COMPILER" in
                gcc-8.1)
                    module load kokkos/2.8.00/gcc81
                    ;;
                intel-2019)
                    module load kokkos/intel-2019
                    ;;
                *)
                    echo "Kokkos not supported with compiler $COMPILER"
                    exit 1
                    ;;
            esac
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
    #bash "$SCRIPT_DIR/run.sh"
    sbatch "$SCRIPT_DIR/run.sh"

else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
