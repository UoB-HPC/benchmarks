#!/bin/bash

DEFAULT_COMPILER=gcc-7.3
DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.3"
    echo "  pgi-18.10"
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
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export CONFIG="skl"_"$COMPILER"_"$MODEL"
export BENCHMARK_EXE=stream-$CONFIG
export SRC_DIR=$SCRIPT_DIR/BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
module swap craype-{broadwell,ivybridge}
module load craype-accel-nvidia35
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        MAKE_OPTS='COMPILER=CRAY TARGET=NVIDIA'
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        MAKE_OPTS='COMPILER=GNU'
        ;;
    pgi-18.10)
        module swap PrgEnv-{cray,pgi}
        module swap pgi pgi/18.10.0
	MAKE_OPTS='COMPILER=PGI TARGET=KEPLER'
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
    export KOKKOS_PATH=/lus/scratch/p02100/kokkos/2.8.00/k20
    MAKE_FILE="Kokkos.make"
    BINARY="kokkos-stream"
    MAKE_OPTS+=' TARGET=GPU'
    if [ "$COMPILER" != "gcc-7.3" ]
    then
      echo
      echo " Must use gcc 7.3 with Kokkos module"
      echo
      exit 1
    fi
    ;;
  acc)
    MAKE_FILE="OpenACC.make"
    BINARY="acc-stream"
    MAKE_OPTS+=' TARGET=KEPLER'
    if [ "$COMPILER" != "pgi-18.10" ]
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
    MAKE_OPTS+=' EXTRA_FLAGS="-arch=sm_35"'
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
