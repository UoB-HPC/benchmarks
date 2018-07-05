#!/bin/bash

# TODO: FFTW vs CRAY-FFTW vs MKL

DEFAULT_COMPILER=gcc-7.3
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  gcc-7.3"
    echo "  intel-2018"
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

export BENCHMARK_PLATFORM=bdw-swan
export BENCHMARK_DIR=$PWD/gromacs-benchmarks
export SRC_DIR=$PWD/gromacs-2018.1
export RUN_DIR=$PWD/gromacs-$BENCHMARK_PLATFORM-$COMPILER
export BUILD_DIR=$RUN_DIR/build

# Set up the environment
case "$COMPILER" in
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        module load fftw
        CMAKE_OPTS="-DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++"
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        module load fftw
        CMAKE_OPTS='-DCMAKE_C_COMPILER=icc -DCMAKE_CXX_COMPILER=icpc'
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
    # Fetch source code if necessary
    if ! "$SCRIPT_DIR/../fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    rm -rf $BUILD_DIR
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR

    # Configure with CMake
    if ! eval cmake $SRC_DIR -DCMAKE_BUILD_TYPE=Release \
        -DGMX_CYCLE_SUBCOUNTERS=ON \
        -DGMX_MPI=OFF -DGMX_GPU=OFF \
        -DGMX_SIMD=AVX2_256 \
        $CMAKE_OPTS
    then
        echo
        echo "Running CMake failed."
        echo
        exit 1
    fi

    # Perform build
    if ! make -j 8
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$BUILD_DIR/bin/gmx" ]
    then
        echo "Executable '$BUILD_DIR/bin/gmx' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    qsub $SCRIPT_DIR/run.job \
        -d $RUN_DIR \
        -o $PWD/gromacs-$BENCHMARK_PLATFORM-$COMPILER.out \
        -N gromacs \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
