#!/bin/bash

# TODO: FFTW vs CRAY-FFTW vs ARMPL

DEFAULT_COMPILER=gcc-7.2
DEFAULT_FFTLIB=cray-fftw-3.3.6
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [FFT-LIB]"
    echo
    echo "Valid compilers:"
    echo "  gcc-7.2"
    echo "  gcc-8.1"
    echo "  arm-18.3"
    echo
    echo "Valid FFT libraries:"
    echo "  armpl-18.3"
    echo "  cray-fftw-3.3.6"
    echo
    echo "The default configuration is '$DEFAULT_COMPILER $DEFAULT_FFTLIB'."
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
FFTLIB=${3:-$DEFAULT_FFTLIB}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export BENCHMARK_PLATFORM=tx2-foxconn
export BENCHMARK_DIR=$PWD/gromacs-benchmarks
export CONFIG="tx2"_"$COMPILER"_"$FFTLIB"
export SRC_DIR=$PWD/gromacs-2018.1
export RUN_DIR=$PWD/gromacs-$CONFIG
export BUILD_DIR=$RUN_DIR/build

# Set up the environment
case "$COMPILER" in
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        CMAKE_OPTS="-DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++"
        ARMPL_VARIANT=gcc-7.1
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        CMAKE_OPTS="-DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++"
        ARMPL_VARIANT=gcc-7.1
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        CMAKE_OPTS="-DCMAKE_C_COMPILER=armclang -DCMAKE_CXX_COMPILER=armclang++"
        ARMPL_VARIANT=arm-18.3
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac
module load cmake

case "$FFTLIB" in
    armpl-18.3)
        if [ -z "$ARMPL_VARIANT" ]
        then
            echo
            echo "Using armpl is not supported for $COMPILER."
            echo
            exit 1
        fi
        module load arm/perf-libs/18.3/$ARMPL_VARIANT
        module unload arm/gcc
        CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_LIBRARY=${ARMPL_DIR}/lib/libarmpl.so"
        CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_INCLUDE_DIR=${ARMPL_DIR}/include"
        ;;
    cray-fftw-3.3.6)
        CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_LIBRARY=/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/lib/libfftw3f.a"
        CMAKE_OPTS="$CMAKE_OPTS -DFFTWF_INCLUDE_DIR=/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/include"
        ;;
    *)
        echo
        echo "Invalid FFT library '$FFTLIB'."
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
        -DGMX_MPI=OFF -DGMX_GPU=OFF -DGMX_DOUBLE=OFF \
        $CMAKE_OPTS
    then
        echo
        echo "Running CMake failed."
        echo
        exit 1
    fi

    # Perform build
    if ! make -j 64
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

    cd $RUN_DIR
    bash $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
