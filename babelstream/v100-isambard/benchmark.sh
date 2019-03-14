#!/bin/bash

DEFAULT_COMPILER=gcc-4.8
DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-4.8"
    echo "  llvm-trunk"
    echo "  pgi-18.10"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  kokkos"
    echo "  cuda"
    echo "  acc"
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
export SRC_DIR=$SCRIPT_DIR/../BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
module load cuda/10.0
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.6.4
        MAKE_OPTS="COMPILER=CRAY TARGET=NVIDIA"
        ;;
    llvm-trunk)
      module load llvm/trunk
      MAKE_OPTS='COMPILER=CLANG TARGET=NVIDIA EXTRA_FLAGS="-Xopenmp-target -march=sm_70"'
      ;;
    gcc-4.8)
        MAKE_OPTS="COMPILER=GNU TARGET=NVIDIA"
        export OMP_PROC_BIND=spread
        ;;
    pgi-18.10)
      module load pgi/18.10
      MAKE_OPTS='COMPILER=PGI TARGET=VOLTA'
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
    # Perform build
    rm -f $BENCHMARK_EXE

    # Select Makefile to use
    case "$MODEL" in
      omp)
        MAKE_FILE="OpenMP.make"
        BINARY="omp-stream"
        ;;
      kokkos)
        module load kokkos/volta
        MAKE_FILE="Kokkos.make"
        BINARY="kokkos-stream"
        MAKE_OPTS+=" CXX=$KOKKOS_PATH/bin/nvcc_wrapper"
        ;;
      cuda)
        MAKE_FILE="CUDA.make"
        BINARY="cuda-stream"
        MAKE_OPTS+=' EXTRA_FLAGS="-arch=sm_70"'
        #NVCC=`which nvcc`
        #CUDA_PATH=`dirname $NVCC`/..
        #export LD_LIBRARY_PATH=$CUDA_PATH/lib64
        ;;
      acc)
        MAKE_FILE="OpenACC.make"
        BINARY="acc-stream"
        ;;
    esac

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

    cd $RUN_DIR
    bash "$SCRIPT_DIR/run.sh"

else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
