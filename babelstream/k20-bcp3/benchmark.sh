#!/bin/bash

DEFAULT_COMPILER=gcc-4.9
DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  gcc-4.9"
    echo "  pgi-18.4"
    echo "  llvm-trunk"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  kokkos"
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
SCRIPT=`readlink -f $0`
SCRIPT_DIR=`readlink -f $(dirname $SCRIPT)`

export CONFIG="k20"_"$COMPILER"_"$MODEL"
export BENCHMARK_EXE=stream-$CONFIG
export SRC_DIR=$SCRIPT_DIR/BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
case "$COMPILER" in
    gcc-4.9)
        module load languages/gcc-4.9.1
        module load cuda/toolkit/7.5.18
        MAKE_OPTS='COMPILER=GNU'
        ;;
    pgi-18.4)
        module load languages/pgi-18.4
	MAKE_OPTS='COMPILER=PGI TARGET=KEPLER FLAGS_PGI="-std=c++0x -O3 -acc"'
        ;;
    llvm-trunk)
        module use /newhome/pa13269/modules/modulefiles
        module load llvm
        MAKE_OPTS='COMPILER=CLANG TARGET=NVIDIA EXTRA_FLAGS="-Xopenmp-target -march=sm_35"'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

# Select Makefile to use, and model specific information
case "$MODEL" in
  omp)
    MAKE_FILE="OpenMP.make"
    BINARY="omp-stream"
    ;;
  kokkos)
    module use /newhome/pa13269/modules/modulefiles
    module load kokkos
    MAKE_FILE="Kokkos.make"
    BINARY="kokkos-stream"
    MAKE_OPTS+=' TARGET=GPU'
    if [ "$COMPILER" != "gcc-4.9" ]
    then
      echo
      echo " Must use gcc 4.9 with Kokkos module"
      echo
      exit 1
    fi
    ;;
  acc)
    MAKE_FILE="OpenACC.make"
    BINARY="acc-stream"
    MAKE_OPTS+=' TARGET=KEPLER'
    if [ "$COMPILER" != "pgi-18.4" ]
    then
      echo
      echo " Must use PGI with OpenACC"
      echo
      exit 1
    fi
  ;;
  cuda)
    MAKE_FILE="CUDA.make"
    BINARY="cuda-stream"
    MAKE_OPTS+=' EXTRA_FLAGS="-arch=sm_35" CUDA_STANDARD="--std=c++11"'
    if [ "$COMPILER" != "gcc-4.9" ]
    then
      echo
      echo 'Must use gcc-4.9 with CUDA'
      echo
      exit 1
    fi
    ;;
  ocl)
    MAKE_FILE="OpenCL.make"
    BINARY="ocl-stream"
    NVCC=`which nvcc`
    CUDA_PATH=`dirname $NVCC`/..
    MAKE_OPTS+=' EXTRA_FLAGS=" -I$CUDA_PATH/include -L$CUDA_PATH/lib64"'
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
    if ! eval make -f $MAKE_FILE -C $SRC_DIR -B $MAKE_OPTS
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

    mkdir -p $RUN_DIR
    # Rename binary
    mv $SRC_DIR/$BINARY $RUN_DIR/$BENCHMARK_EXE

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$RUN_DIR/$BENCHMARK_EXE" ]
    then
        echo "Executable '$RUN_DIR/$BENCHMARK_EXE' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    qsub $SCRIPT_DIR/run.job \
        -d $RUN_DIR \
        -o BabelStream-$CONFIG.out \
        -N babelstream \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
