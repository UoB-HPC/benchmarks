#!/bin/bash

set -e

DEFAULT_COMPILER=gcc-8.1
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  gcc-8.1"
    echo "  pgi-18"
    echo
    echo "Valid models:"
    echo "  acc"
    echo "  omp"
    echo "  kokkos"
    echo
    echo "The default compiler is '$DEFAULT_COMPILER'."
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
SCRIPT_DIR=`realpath "$(dirname $SCRIPT)"`

export BENCHMARK_EXE=tea_leaf
export CONFIG="power9_${COMPILER}_${MODEL}"
export SRC_DIR=$PWD/TeaLeaf_ref
export RUN_DIR=$PWD/TeaLeaf-$CONFIG


# Set up the environment
case "$COMPILER" in
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        MAKE_OPTS='OPTIONS=-DNO_MPI CFLAGS_GNU="-O3 -mcpu=power9 -funroll-loops -std=gnu99"'
        ;;
    pgi-18)
        module purge
        module load pgi/18.10
        MAKE_OPTS='OPTIONS=-DNO_MPI COMPILER=PGI CC=pgcc CPP=gpc++'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

case "$MODEL" in
    acc)
        case "$COMPILER" in
            pgi-18)
                ;;
            *)
                echo "OpenACC not available with compiler '$COMPILER'"
                exit 1
                ;;
        esac
        export SRC_DIR="$PWD/TeaLeaf/2d"
        export BENCHMARK_EXE=tealeaf
        MAKE_OPTS+=" KERNELS=openacc OACC_FLAGS='-ta=multicore -tp=pwr9'"
        ;;
    omp)
        export SRC_DIR="$PWD/TeaLeaf/2d"
        export BENCHMARK_EXE=tealeaf
        ;;
    kokkos)
        case "$COMPILER" in
            gcc-8.1)
                module load kokkos/power9/gcc-8.1
                ;;
            *)
                echo "Kokkos not available with compiler $COMPILER"
                exit 1
                ;;
        esac
        export SRC_DIR="$PWD/TeaLeaf/2d"
        export BENCHMARK_EXE=tealeaf
        MAKE_OPTS='KERNELS=kokkos OPTIONS=-DNO_MPI'
        sed -i 's/-march=native/-mcpu=power9/' "$SRC_DIR/make.flags"
        ;;
    *)
        echo
        echo "Invalid model '$MODEL'."
        usage
        exit 2
        ;;
esac


# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! "$SCRIPT_DIR/../fetch.sh" "$MODEL"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    # Perform build
    rm -f $SRC_DIR/$BENCHMARK_EXE $RUN_DIR/$BENCHMARK_EXE
    make -C "$SRC_DIR" clean
    if ! eval make -j 8 -C $SRC_DIR -B $MAKE_OPTS
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

    case "$MODEL" in
        kokkos|acc)
            cp $SRC_DIR/tea.problems $RUN_DIR
            echo "4000 4000 10 9.5462351582214282e+01" >> "$RUN_DIR/tea.problems"
            ;;
    esac

    cd "$RUN_DIR"
    bash "$SCRIPT_DIR/run.sh"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
