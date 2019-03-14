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
    echo
    echo "Valid models:"
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
COMPILER=${2:-$DEFAULT_COMPILER}
export MODEL=${3:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath "$(dirname $SCRIPT)"`

export BENCHMARK_EXE=tea_leaf
export CONFIG="ampere_${COMPILER}_${MODEL}"
export SRC_DIR=$PWD/TeaLeaf_ref
export RUN_DIR=$PWD/TeaLeaf-$CONFIG


# Set up the environment
case "$COMPILER" in
    gcc-8.1)
        module purge
        module load gcc/8.1
        MAKE_OPTS='COMPILER=GNU'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -march=armv8-a -funroll-loops -cpp -ffree-line-length-none -ffast-math -ffp-contract=fast"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -march=armv8-a -funroll-loops -ffast-math -ffp-contract=fast"'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

case "$MODEL" in
    omp)
        module load openmpi/3.0.3/gcc-8.1
        export SRC_DIR=$PWD/TeaLeaf_ref
        export BENCHMARK_EXE=tea_leaf
        ;;
    kokkos)
        module load kokkos/gcc-8.1
        export SRC_DIR=$PWD/TeaLeaf/2d
        export BENCHMARK_EXE=tealeaf
        MAKE_OPTS='KERNELS=kokkos COMPILER=GNU OPTIONS=-DNO_MPI'
        sed -i 's/-march=native/-march=armv8-a/' "$SRC_DIR/make.flags"
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
    make -C $SRC_DIR clean
    if ! eval make -j 32 -C $SRC_DIR -B $MAKE_OPTS
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

    if [ "$MODEL" = kokkos ]; then
        cp $SRC_DIR/tea.problems $RUN_DIR
        echo "4000 4000 10 9.5462351582214282e+01" >> "$RUN_DIR/tea.problems"
    fi

    cd "$RUN_DIR"
    bash "$SCRIPT_DIR/run.sh"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
