#!/bin/bash

# TODO: OpenBLAS vs CRAY-LIBSCI vs ARMPL
# TODO: libsmm?

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
export CONFIG=$BENCHMARK_PLATFORM-$COMPILER-$FFTLIB
export SRC_DIR=$PWD/cp2k-5.1
export RUN_DIR=$PWD/cp2k-$CONFIG

# Set up the environment
case "$COMPILER" in
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        module load openmpi/3.0.0/gcc-7.2
        export CC=mpicc
        export FC=mpifort
        export LD=mpifort
        export CFLAGS="-Ofast -mcpu=thunderx2t99"
        export FCFLAGS="-Ofast -fopenmp -mcpu=thunderx2t99 -funroll-loops -ffast-math -ffp-contract=fast"
        export FCFLAGS="$FCFLAGS -ftree-vectorize -ffree-form -ffree-line-length-512"
        export LIBS="/lustre/projects/bristol/modules-arm/scalapack/2.0.2-openblas/lib/libscalapack.a"
        export LIBS="$LIBS /lustre/projects/bristol/modules-arm/openblas/0.2.20-nothreads/lib/libopenblas.a"
        ARMPL_VARIANT=gcc-7.1
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        module load openmpi/3.0.0/gcc-8.1
        export CC=mpicc
        export FC=mpifort
        export LD=mpifort
        export CFLAGS="-Ofast -mcpu=thunderx2t99"
        export FCFLAGS="-Ofast -fopenmp -mcpu=thunderx2t99 -funroll-loops -ffast-math -ffp-contract=fast"
        export FCFLAGS="$FCFLAGS -ftree-vectorize -ffree-form -ffree-line-length-512"
        export LIBS="/lustre/projects/bristol/modules-arm/scalapack/2.0.2-openblas/lib/libscalapack.a"
        export LIBS="$LIBS /lustre/projects/bristol/modules-arm/openblas/0.2.20-nothreads/lib/libopenblas.a"
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        module load openmpi/3.0.0/arm-18.3
        export CC=mpicc
        export FC=mpifort
        export LD=mpifort
        export CFLAGS="-Ofast -mcpu=thunderx2t99"
        export FCFLAGS="-Ofast -fopenmp -mcpu=thunderx2t99 -funroll-loops -ffast-math -ffp-contract=fast"
        export FCFLAGS="$FCFLAGS -ftree-vectorize -ffree-form"
        export LIBS="/lustre/projects/bristol/modules-arm/scalapack/2.0.2-openblas/lib/libscalapack.a"
        export LIBS="$LIBS /lustre/projects/bristol/modules-arm/openblas/0.2.20-nothreads/lib/libopenblas.a"
        ARMPL_VARIANT=arm-18.3
        ;;
    cce-8.7)
        module swap cce cce/8.7.0
        export CC=cc
        export FC=ftn
        export LD=ftn
        export CFLAGS=""
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

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
        export FCFLAGS="$FCFLAGS -I$ARMPL_DIR/include"
        export LIBS="$LIBS -larmpl"
        ;;
    cray-fftw-3.3.6)
        export FCFLAGS="$FCFLAGS -I/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/include"
        export LDFLAGS="$LDFLAGS -L/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/lib"
        export LIBS="$LIBS -lfftw3 -lfftw3_threads"
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

    # Generate arch config file
    envsubst <$SCRIPT_DIR/template.psmp >$SRC_DIR/arch/$CONFIG.psmp

    # Perform build
    cd $SRC_DIR/makefiles
    make ARCH=$CONFIG VERSION=psmp clean
    if ! make ARCH=$CONFIG VERSION=psmp -j 256
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$SRC_DIR/exe/$CONFIG/cp2k.psmp" ]
    then
        echo "Executable '$SRC_DIR/exe/$CONFIG/cp2k.psmp' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    mkdir -p $RUN_DIR
    cd $RUN_DIR
    bash $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
