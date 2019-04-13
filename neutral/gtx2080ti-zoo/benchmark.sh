#!/bin/bash

DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid models:"
    echo "   kokkos"
    echo "   cuda"
    echo "   oacc"
    echo "   ocl"
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

export BENCHMARK_EXE=neutral."$MODEL"
export CONFIG="gtx2080ti"_"$MODEL"
export RUN_DIR=$PWD/neutral-$CONFIG

FETCH_OPTION=''

# Set up the environment
    
case "$MODEL" in
    cuda)
        FETCH_FILE='fetch.sh'
        export SRC_DIR=$PWD/arch/neutral
        module load cuda/10.1
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast"'
        MAKE_OPTS="$MAKE_OPTS"' KERNELS="cuda" NVCC_FLAGS="-O3 -arch=sm_75 -DTILES -g -D__STDC_CONSTANT_MACROS -DSoA"'
        NVCC=`which nvcc`
        export CUDA_PATH=`dirname $NVCC`/..
        ;;
    kokkos)
        FETCH_FILE='fetch_kokkos.sh'
        FETCH_OPTION='GPU'
        export SRC_DIR=$PWD/neutral_kokkos
        module load kokkos/turing
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast"'
        ;;
    oacc)
        FETCH_FILE='fetch.sh'
        export SRC_DIR=$PWD/arch/neutral
        module load pgi/18.10
        module load cuda/10.1
        MAKE_OPTS='COMPILER=PGI ARCH_COMPILER_CC=pgcc ARCH_COMPILER_CPP=gpc++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_PGI="-fast -acc -ta=tesla:cc70 -Minfo=acc "'
        MAKE_OPTS="$MAKE_OPTS"' KERNELS="oacc"'
        ;;
    ocl)    
         FETCH_FILE='fetch_ocl.sh'
         export SRC_DIR=$PWD/neutral_ocl
         module load cuda/10.1
         MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
         MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast"'
         MAKE_OPTS="$MAKE_OPTS"' KERNELS="opencl_gpu"'
         export BENCHMARK_EXE=neutral.opencl_gpu
         NVCC=`which nvcc`
         export CUDA_PATH=`dirname $NVCC`/..
         ;;
    *)
        echo
        echo "Invalid module '$MODEL'."
        usage
        exit 1
        ;;
esac


# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! "$SCRIPT_DIR/../$FETCH_FILE" $FETCH_OPTION
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    # Hack for non-x86 systems
    sed -i '/defined(__powerpc__)$/s/$/ \&\& !defined(__aarch64__)/' $SRC_DIR/Random123/features/gccfeatures.h
    sed -i 's/ifdef __powerpc__/if defined(__powerpc__) \&\& !defined(__clang__)/g' $SRC_DIR/Random123/features/gccfeatures.h
    sed -i '/defined(__i386__)$/s/$/ \&\& !defined(__powerpc__)/' $SRC_DIR/Random123/features/pgccfeatures.h

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
