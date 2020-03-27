#!/bin/bash

set -u

function usage
{
    echo
    echo "Usage:"
    echo "  # Build the benchmark"
    echo "  ./benchmark.sh build [COMPILER] [BLAS-LIB] [FFT-LIB]"
    echo
    echo "  # Run on N nodes"
    echo "  ./benchmark.sh run scale-N [COMPILER] [BLAS-LIB] [FFT-LIB]"
    echo
    echo "Valid compilers:"
    for compiler in $COMPILERS
    do
      echo "  $compiler"
    done
    echo
    echo "Valid BLAS libraries:"
    for blaslib in $BLASLIBS
    do
      echo "  $blaslib"
    done
    echo "Valid FFT libraries:"
    for fftlib in $FFTLIBS
    do
      echo "  $fftlib"
    done
    echo
    echo "The default configuration is '$DEFAULT_COMPILER $DEFAULT_BLASLIB $DEFAULT_FFTLIB'."
    echo
}

# Process arguments
if [ $# -lt 1 ]
then
    usage
    exit 1
fi

ACTION="$1"
if [ "$ACTION" == "run" ]
then
    shift
    export RUN_ARGS="$1"
fi
COMPILER="${2:-$DEFAULT_COMPILER}"
BLASLIB="${3:-$DEFAULT_BLASLIB}"
FFTLIB="${4:-$DEFAULT_FFTLIB}"
SCRIPT="`realpath $0`"
SCRIPT_DIR="`realpath $(dirname $SCRIPT)`"

export CONFIG="${ARCH}_${COMPILER}_${FFTLIB}"
export SRC_DIR="$PWD/castep-19.1"
export BENCHMARK_DIR="$PWD/castep-benchmarks"
export CFG_DIR="$PWD/castep/${CONFIG}"
export BUILD_DIR="$CFG_DIR/build"
export BENCHMARK_NODE="$PWD/castep-benchmarks/replace_with_castep_benchmark.bm"

# Set up the environment
setup_env

# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! "$SCRIPT_DIR/fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    ## TODO: Change this to allow different combinations of compiler, blaslib, fftlib
    echo ""
    echo "Building CASTEP"
    echo ""
    cd $SRC_DIR 
    cp obj/platforms/linux_x86_64_cray-XT.mk obj/platforms/linux_arm64_cray-XC.mk
    sed -i 's/COMMS_ARCH := serial/COMMS_ARCH := mpi/g' $SRC_DIR/Makefile
    sed -i 's/FFT := default/FFT := fftw3/g' $SRC_DIR/Makefile
    sed -i 's/MATHLIBS := default/MATHLIBS := scilib/g' $SRC_DIR/Makefile

    mkdir -p $BUILD_DIR
    unset CPU
    make -j8 CASTEP_ARCH=linux_arm64_cray-XC clean
    # Perform build
    if ! printf '\n\n' | make -j8 CASTEP_ARCH=linux_arm64_cray-XC
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

    if ! printf 'y' | make -j8 INSTALL_DIR=$BUILD_DIR  install 
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

    cd $SCRIPT_DIR

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$BUILD_DIR/castep.mpi" ]
    then
        echo "Executable '$BUILD_DIR/bin/linux_arm64_cray-XC/castep.mpi' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    cd "$CFG_DIR"

    if [[ "$RUN_ARGS" == scale-* ]]
    then
        export NODES=${RUN_ARGS#scale-}
        if ! [[ "$NODES" =~ ^[0-9]+$ ]]
        then
            echo
            echo "Invalid node count for 'run scale-N' action"
            echo
            exit 1
        fi
        JOBSCRIPT=scale.job
    else
        echo
        echo "Invalid 'run' argument '$RUN_ARGS'"
        usage
        exit 1
    fi

    # Some systems use a different shell for jobs, breaking exported functions
    unset -f setup_env

    # Submit job
    mkdir -p "$RUN_ARGS"
    cd "$RUN_ARGS"
    rm -rf *
    cp $BENCHMARK_DIR/Al2O3-slab/3x3/* . 
    echo $RUN_ARGS
    qsub -l select=$NODES$PBS_RESOURCES \
        -o job.out \
        -N "castep_${RUN_ARGS}_${CONFIG}" \
        -V \
        "$PLATFORM_DIR/$JOBSCRIPT"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
