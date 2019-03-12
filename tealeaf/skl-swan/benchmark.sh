#!/bin/bash

DEFAULT_COMPILER=intel-2018
DEFAULT_MODEL=omp
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
MODEL=${3:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath "$(dirname $SCRIPT)"`

export BENCHMARK_EXE=tea_leaf
export CONFIG="skl_${COMPILER}_${MODEL}"
export SRC_DIR=$PWD/TeaLeaf_ref
export RUN_DIR=$PWD/TeaLeaf-$CONFIG


# Set up the environment
module swap craype-{broadwell,x86-skylake}
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -march=skylake-avx512 -funroll-loops -cpp -ffree-line-length-none -ffast-math -ffp-contract=fast"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -march=skylake-avx512 -funroll-loops -ffast-math -ffp-contract=fast"'
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_INTEL="-O3 -no-prec-div -fpp -align array64byte -xCORE-AVX512"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xCORE-AVX512"'
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
        export SRC_DIR=$PWD/TeaLeaf_ref
        export BENCHMARK_EXE=tea_leaf
        ;;
    kokkos)
	echo "Kokkos module not available"
	exit 99
        # module use /lustre/projects/bristol/modules-arm-phase2/modulefiles
        # module load kokkos/2.8.00
        export SRC_DIR=$PWD/TeaLeaf/2d
        export BENCHMARK_EXE=tealeaf
        MAKE_OPTS='KERNELS=kokkos OPTIONS=-DNO_MPI'
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
        cp $SRC_DIR/tea.problems $RUN_DIR
        echo "4000 4000 10 9.5462351582214282e+01" >> "$RUN_DIR/tea.problems"
    fi

    qsub $SCRIPT_DIR/run.job \
        -d $RUN_DIR \
        -o TeaLeaf-$CONFIG.out \
        -N "tealeaf-$MODEL" \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
