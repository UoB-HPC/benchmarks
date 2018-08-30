#!/bin/bash

DEFAULT_COMPILER=gcc-7.2
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.2"
    echo "  gcc-8.1"
    echo "  arm-18.3"
    echo "  arm-18.4"
    echo
    echo "The default configuration is '$DEFAULT_COMPILER'."
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
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export BENCHMARK_EXE=neutral.omp3
export CONFIG="tx2"_"$COMPILER"
export SRC_DIR=$PWD/arch/neutral
export RUN_DIR=$PWD/neutral-$CONFIG


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.0
        MAKE_OPTS='COMPILER=CRAY ARCH_COMPILER_CC=cc ARCH_COMPILER_CPP=CC CFLAGS_CRAY="-hfp3"'
        ;;
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast"'
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast"'
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=armclang ARCH_COMPILER_CPP=armclang++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast"'
        ;;
    arm-18.4)
        module purge
        module load arm/hpc-compiler/18.4
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=armclang ARCH_COMPILER_CPP=armclang++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast"'
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

    # Hack for non-x86 systems
    sed -i '/defined(__powerpc__)$/s/$/ \&\& !defined(__aarch64__)/' $SRC_DIR/Random123/features/gccfeatures.h

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

    cd $RUN_DIR
    bash $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
