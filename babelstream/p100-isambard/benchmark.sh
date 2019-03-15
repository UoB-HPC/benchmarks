#!/bin/bash

DEFAULT_COMPILER=cce-8.7
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-6.1"
    echo "  gcc-4.8"
    echo "  llvm-trunk"
    echo "  pgi-18.10"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  kokkos"
    echo "  cuda"
    echo "  acc"
    echo "  ocl"
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

export CONFIG="p100"_"$COMPILER"_"$MODEL"
export BENCHMARK_EXE=stream-$CONFIG
export SRC_DIR=$SCRIPT_DIR/BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
module swap craype-{mic-knl,broadwell}
module load craype-accel-nvidia60
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.6.4
        MAKE_OPTS="COMPILER=CRAY TARGET=NVIDIA"
        ;;
    llvm-trunk)
      module load llvm/trunk
      MAKE_OPTS='COMPILER=CLANG TARGET=NVIDIA EXTRA_FLAGS="-Xopenmp-target -march=sm_60"'
      ;;
    gcc-6.1)
        module swap gcc gcc/6.1.0
        MAKE_OPTS="COMPILER=GNU TARGET=GPU"
        ;;
    gcc-4.8)
        module unload gcc
        MAKE_OPTS="COMPILER=GNU TARGET=GPU"
        ;;
    pgi-18.10)
      module load PrgEnv-pgi
      module swap pgi pgi/18.10
      MAKE_OPTS='COMPILER=PGI TARGET=PASCAL'
      ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

# Select Makefile to use
case "$MODEL" in
  omp)
    MAKE_FILE="OpenMP.make"
    BINARY="omp-stream"
    ;;
  kokkos)
    module unload cudatoolkit/8.0.44
    module load kokkos/pascal
    MAKE_FILE="Kokkos.make"
    BINARY="kokkos-stream"
    if [ "$COMPILER" != "gcc-4.8" ]
    then
      echo
      echo " Must use gcc-4.8 with Kokkos"
      echo
      stop
    fi
    ;;
  cuda)
    module swap gcc gcc/4.9.1
    MAKE_FILE="CUDA.make"
    BINARY="cuda-stream"
    MAKE_OPTS+=' EXTRA_FLAGS="-arch=sm_60"'
    ;;
  acc)
    MAKE_FILE="OpenACC.make"
    BINARY="acc-stream"
    ;;
  ocl)
    NVCC=`which nvcc`
    CUDA_PATH=`dirname $NVCC`/..
    MAKE_FILE="OpenCL.make"
    BINARY="ocl-stream"
    MAKE_OPTS+=' EXTRA_FLAGS="-I$CUDA_PATH/include/ -L$CUDA_PATH/lib64"'
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
    rm -f $BENCHMARK_EXE


    if ! eval make -f $MAKE_FILE -C $SRC_DIR -B $MAKE_OPTS
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

    # Rename binary
    mv $SRC_DIR/$BINARY $BENCHMARK_EXE

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$BENCHMARK_EXE" ]
    then
        echo "Executable '$BENCHMARK_EXE' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    qsub \
        -o BabelStream-$CONFIG.out \
        -N babelstream \
        -V \
        $SCRIPT_DIR/run.job \

else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
