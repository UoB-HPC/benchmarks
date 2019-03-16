#!/bin/bash

DEFAULT_COMPILER=intel-2018
DEFAULT_MODEL=mpi
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.3"
    echo "  intel-2018"
    echo
    echo "Valid models:"
    echo "  mpi"
    echo "  omp"
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

export BENCHMARK_TEMPLATE=$SCRIPT_DIR/../benchmark.in
export CONFIG="knl"_"$COMPILER"_"$MODEL"
export SRC_DIR=$PWD/SNAP/src
export RUN_DIR=$PWD/SNAP-$CONFIG


# Set up the environment
module swap craype-{broadwell,mic-knl}
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.9
        export BENCHMARK_EXE=csnap
        MAKE_OPTS='TARGET=csnap FORTRAN=ftn FFLAGS=-hfp3 PP=cpp'
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        export BENCHMARK_EXE=gsnap
        MAKE_OPTS='TARGET=gsnap FORTRAN=ftn FFLAGS="-Ofast -march=knl -ffast-math -ffp-contract=fast -fopenmp"'
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        export BENCHMARK_EXE=isnap
        MAKE_OPTS='TARGET=isnap FORTRAN=ftn FFLAGS="-O3 -qopenmp -ip -align array32byte -qno-opt-dynamic-align -fno-fnalias -fp-model fast -fp-speculation fast -xMIC-AVX512"'
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

    case "$MODEL" in
      mpi)
        qsub $SCRIPT_DIR/run.job \
            -d $RUN_DIR \
            -o snap-$CONFIG.out \
            -N snap \
            -V
        ;;
      omp)
        qsub $SCRIPT_DIR/run_omp.job \
            -d $RUN_DIR \
            -o snap-$CONFIG.out \
            -N snap \
            -V
        ;;
      esac

else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
