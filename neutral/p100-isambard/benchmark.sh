#!/bin/bash

DEFAULT_COMPILER=gcc-4.8
DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  gcc-6.1"
    echo "  gcc-4.8"
    echo "  pgi-18"
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
export CONFIG="p100"_"$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/neutral-$CONFIG

FETCH_OPTION=''

module purge
module use /lustre/projects/bristol/modules/modulefiles
module load module-git

# Set up the environment
case "$COMPILER" in
    gcc-6.1)
        module load gcc/6.1.0
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast "'
        ;;      
    gcc-4.8)
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast"'
        ;;
    pgi-18)
        module load pgi/18.10 
        MAKE_OPTS='COMPILER=PGI ARCH_COMPILER_CC=pgcc ARCH_COMPILER_CPP=gpc++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_PGI="-fast -acc -ta=tesla:cc60 -Minfo=acc "'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

case "$MODEL" in 
    cuda)
        FETCH_FILE='fetch.sh'
        export SRC_DIR=$PWD/arch/neutral
        module load cudatoolkit/9.1.85
        MAKE_OPTS="$MAKE_OPTS"' KERNELS="cuda" NVCC_FLAGS="-O3 -arch=sm_60 -DTILES -g -D__STDC_CONSTANT_MACROS -DSoA"'
        NVCC=`which nvcc`
        export CUDA_PATH=`dirname $NVCC`/..
        ;;
    kokkos)
        module load kokkos/pascal
        FETCH_FILE='fetch_kokkos.sh'
        FETCH_OPTION='GPU'
        export SRC_DIR=$PWD/neutral_kokkos
        if [ "$COMPILER" != "gcc-4.8" ]
        then
          echo
          echo "Must use gcc-4.8 with Kokkos"
          echo
          exit 1
        fi
        ;;
    oacc)
        FETCH_FILE='fetch.sh'
        export SRC_DIR=$PWD/arch/neutral
        MAKE_OPTS="$MAKE_OPTS"' KERNELS="oacc"'
        if [ "$COMPILER" != "pgi-18" ]
        then 
          echo "Must use pgi-18 with OpenAcc"
          echo
          exit 1
        fi
        ;;
    ocl)    
         FETCH_FILE='fetch_ocl.sh'
         export SRC_DIR=$PWD/neutral_ocl
         MAKE_OPTS="$MAKE_OPTS"' KERNELS="opencl_gpu"'
         export BENCHMARK_EXE=neutral.opencl_gpu
         module load cudatoolkit/9.1.85
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
