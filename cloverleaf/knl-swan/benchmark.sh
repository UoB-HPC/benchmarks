#!/bin/bash

DEFAULT_COMPILER=intel-2019
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  intel-2018"
    echo "  intel-2019"
    echo "  pgi-18"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  kokkos"
    echo "  acc"
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

export BENCHMARK_EXE=clover_leaf
export CONFIG="knl_${COMPILER}_${MODEL}"
export SRC_DIR=$PWD/CloverLeaf_ref
export RUN_DIR=$PWD/CloverLeaf-$CONFIG


# Set up the environment
module swap craype-{broadwell,mic-knl}
case "$COMPILER" in
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_INTEL="-O3 -no-prec-div -fpp -align array64byte -xMIC-AVX512"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xMIC-AVX512"'
        ;;
    intel-2019)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/19.0.0.117
        MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_INTEL="-O3 -no-prec-div -fpp -align array64byte -xMIC-AVX512"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xMIC-AVX512"'
        ;;
    pgi-18)
        module swap craype-{mic-knl,broadwell} # PrgEnv-pgi is not compatible with craype-mic-knl
        module swap PrgEnv-{cray,pgi}
        module swap pgi pgi/18.10.0
        MAKE_OPTS='COMPILER=PGI C_MPI_COMPILER=cc MPI_COMPILER=ftn'
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
        export SRC_DIR=$PWD/CloverLeaf_ref
        export BENCHMARK_EXE=clover_leaf
        ;;
    kokkos)
        module use /lus/snx11029/p02100/modules/modulefiles
        module load kokkos/2.8.00/intel/knl_ivdep
        MAKE_OPTS='CXX=CC OPTIONS="-qopt-report=5"'
        export SRC_DIR=$PWD/cloverleaf_kokkos
        ;;
    acc)
        MAKE_OPTS=$MAKE_OPTS' FLAGS_PGI="-O3 -Mpreprocess -fast -acc -ta=multicore -tp=knl" CFLAGS_PGI="-O3 -ta=multicore -tp=knl" OMP_PGI=""'
        export SRC_DIR=$PWD/CloverLeaf-OpenACC
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
    if ! eval "$SCRIPT_DIR/../fetch.sh $MODEL"
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

    if [ "$MODEL" = kokkos ]; then
        :
    fi

    qsub \
        -o CloverLeaf-$CONFIG.out \
        -N "cloverleaf-$MODEL" \
        -V \
        $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
