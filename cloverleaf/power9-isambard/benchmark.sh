#!/bin/bash

set -e

DEFAULT_COMPILER=pgi-18
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
    echo "  mpi"
    echo "  omp"
    echo "  acc"
    echo "  kokkos"
    echo
    echo "The default configuration is '$DEFAULT_COMPILER $DEFAULT_MODEL'."
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
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export BENCHMARK_EXE=clover_leaf
export CONFIG="power9"_"$COMPILER"_"$MODEL"
export SRC_DIR=$PWD/CloverLeaf_ref
export RUN_DIR=$PWD/CloverLeaf-$CONFIG


# Set up the environment
if ! grep -q "/lustre/projects/bristol/modules-power/modulefiles" <<<"$MODULEPATH"; then
    module use /lustre/projects/bristol/modules-power/modulefiles
fi
module purge
case "$COMPILER" in
    gcc-8.1)
        module load gcc/8.1.0 openmpi/3.0.2/gcc8
        MAKE_OPTS='COMPILER=GNU'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=power9 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=power9 -funroll-loops"'
        ;;
    pgi-18)
        module load pgi/18.10 openmpi/2.1.2/2018
        MAKE_OPTS='COMPILER=PGI'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_PGI="-fast"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_PGI="-fast"'
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
     export SRC_DIR="$PWD/CloverLeaf-OpenACC"
     MAKE_OPTS='COMPILER=PGI FLAGS_PGI="-O3 -Mpreprocess -fast -acc -ta=multicore -tp=pwr9" CFLAGS_PGI="-O3 -ta=multicore -tp=pwr9" OMP_PGI=""'
     ;;
  kokkos)
     export SRC_DIR="$PWD/cloverleaf_kokkos"
     module load kokkos/power9/gcc-8.1
     MAKE_OPTS=''
     ;;
esac


# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! eval "$SCRIPT_DIR/../fetch.sh $MODEL"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    # Perform build
    rm -f $SRC_DIR/$BENCHMARK_EXE $RUN_DIR/$BENCHMARK_EXE
    make -C "$SRC_DIR" clean
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

    cd "$RUN_DIR"
    bash $SCRIPT_DIR/run.sh
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
