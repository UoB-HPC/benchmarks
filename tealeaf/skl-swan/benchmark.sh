#!/bin/bash

DEFAULT_COMPILER=intel-2019
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
    echo "  intel-2019"
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
    intel-2019)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/19.0.0.117
        MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_INTEL="-O3 -no-prec-div -fpp -align array64byte -xCORE-AVX512"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xCORE-AVX512"'
        ;;
    pgi-18)
        module swap craype-{x86-skylake,broadwell} # PrgEnv-pgi is not compatible with craype-skylake
        module swap PrgEnv-{cray,pgi}
        module swap pgi pgi/18.10.0
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
        if ! [[ "$COMPILER" =~ pgi ]]; then
            echo "OpenACC not available with compiler '$COMPILER'"
            exit 1
        fi

        export SRC_DIR="$PWD/TeaLeaf/2d"
        export BENCHMARK_EXE=tealeaf
        MAKE_OPTS+=" KERNELS=openacc OACC_FLAGS='-ta=multicore -tp=skylake'"
        ;;
    omp)
        if [[ "$COMPILER" =~ pgi ]]; then
            echo "OpenMP not available with compiler '$COMPILER'"
            exit 1
        fi

        export SRC_DIR=$PWD/TeaLeaf_ref
        export BENCHMARK_EXE=tea_leaf
        ;;
    kokkos)
        module use /lus/scratch/p02555/modules/modulefiles
        module load kokkos/skylake
        export SRC_DIR=$PWD/TeaLeaf/2d
        export BENCHMARK_EXE=tealeaf
        MAKE_OPTS='KERNELS=kokkos COMPILER=INTEL CC=icc CPP=icpc OPTIONS=-DNO_MPI'
        sed -i 's/-xhost/-xCORE-AVX512/' "$SRC_DIR/make.flags"
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

    if [ "$MODEL" = kokkos ] || [ "$MODEL" = acc ]; then
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
