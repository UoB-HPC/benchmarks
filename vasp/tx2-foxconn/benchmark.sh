#!/bin/bash

DEFAULT_COMPILER=gcc-7.2
DEFAULT_BLASLIB=armpl-18.3
DEFAULT_FFTLIB=cray-fftw-3.3.6
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [BLAS-LIB] [FFT-LIB]"
    echo
    echo "Valid compilers:"
    echo "  gcc-7.2"
    echo "  gcc-8.1"
    echo "  cce-8.7"
    echo
    echo "Valid BLAS libraries:"
    echo "  openblas-0.2"
    echo "  armpl-18.3"
    echo "  libsci-17.09"
    echo
    echo "Valid FFT libraries:"
    echo "  armpl-18.3"
    echo "  cray-fftw-3.3.6"
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

ACTION=$1
COMPILER=${2:-$DEFAULT_COMPILER}
BLASLIB=${3:-$DEFAULT_BLASLIB}
FFTLIB=${4:-$DEFAULT_FFTLIB}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export CONFIG="tx2"_"$COMPILER"_"$BLASLIB"_"$FFTLIB"
export CFG_DIR=$PWD/vasp-$CONFIG
export SRC_DIR=$CFG_DIR/vasp.5.4.4
export RUN_DIR=$CFG_DIR/vasp-test-suite/PdO/91
export BENCHMARK_DIR=$PWD/vasp-test-suite

# Set up the environment
case "$COMPILER" in
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        module load openmpi/3.0.0/gcc-7.2
        export FC=mpifort
        export FCL=mpifort
        export CC=gcc
        export CXX=g++
        export CPP="gcc -E -P -C -w"
        export OFLAG="-O3 -mcpu=thunderx2t99 -ffp-contract=fast -ffast-math"
        export FFLAGS="-w"
        export FREE="-ffree-form -ffree-line-length-none"
        ARMPL_VARIANT=gcc-7.1
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        module load openmpi/3.0.0/gcc-8.1
        export FC=mpifort
        export FCL=mpifort
        export CC=gcc
        export CXX=g++
        export CPP="gcc -E -P -C -w"
        export OFLAG="-O3 -mcpu=thunderx2t99 -ffp-contract=fast -ffast-math"
        export FFLAGS="-w"
        export FREE="-ffree-form -ffree-line-length-none"
        ;;
    arm-18.4)
        module purge
        module load arm/hpc-compiler/18.4
        module load openmpi/3.0.0/arm-18.4
        export FC=mpifort
        export FCL=mpifort
        export CC=armclang
        export CXX=armclang++
        export CPP="gcc -E -P -C -w"
        export OFLAG="-O3 -mcpu=thunderx2t99 -ffp-contract=fast -ffast-math"
        export FFLAGS="-w"
        export FREE="-ffree-form -ffree-line-length-none"
        ARMPL_VARIANT=arm-18.4
        ;;
    cce-8.7)
        module swap cce cce/8.7.0
        export FC=ftn
        export FCL=ftn
        export CC=cc
        export CXX=CC
        export CPP="cpp -E -P -w -traditional"
        export OFLAG="-O2"
        export FREE="-ffree"
        export FFLAGS="-dC -rmo -emEb -F noupcase -F backslash"
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

case "$BLASLIB" in
    openblas-0.2)
        export LLIBS="$LLIBS /lustre/projects/bristol/modules-arm/scalapack/2.0.2-openblas/lib/libscalapack.a"
        export LLIBS="$LLIBS /lustre/projects/bristol/modules-arm/openblas/0.2.20-nothreads/lib/libopenblas.a"
        ;;
    armpl-18.3)
        export LLIBS="$LLIBS /lustre/projects/bristol/modules-arm/scalapack/2.0.2-armpl/lib/libscalapack.a"
        ARMPL_VERSION=18.3
        ;;
    armpl-18.4)
        export LLIBS="$LLIBS /lustre/projects/bristol/modules-arm/scalapack/2.0.2-armpl/lib/libscalapack.a"
        ARMPL_VERSION=18.4
        ;;
    libsci-17.09)
        if [ "$FC" != "ftn" ]
        then
            echo
            echo "Using libsci requires CCE on this platform."
            echo
            exit 1
        fi
        module swap cray-libsci cray-libsci/17.09.1.2
        ;;
    *)
        echo
        echo "Invalid BLAS library '$BLASLIB'."
        usage
        exit 1
        ;;
esac

case "$FFTLIB" in
    armpl-18.3)
        if [ -n "$ARMPL_VERSION" -a "$ARMPL_VERSION" != "18.3" ]
        then
            echo "Arm PL version mismatch"
            exit 1
        fi
        ARMPL_VERSION=18.3
        ;;
    armpl-18.4)
        if [ -n "$ARMPL_VERSION" -a "$ARMPL_VERSION" != "18.4" ]
        then
            echo "Arm PL version mismatch"
            exit 1
        fi
        ARMPL_VERSION=18.4
        ;;
    cray-fftw-3.3.6)
        export INCS="$INCS -I/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/include"
        export LLIBS="$LLIBS -L/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/lib -lfftw3"
        ;;
    *)
        echo
        echo "Invalid FFT library '$FFTLIB'."
        usage
        exit 1
        ;;
esac

# Add ARMPL flags last if used
if [ -n "$ARMPL_VERSION" ]
then
    if [ -z "$ARMPL_VARIANT" ]
    then
        echo
        echo "Using armpl is not supported for $COMPILER."
        echo
        exit 1
    fi
    module load arm/perf-libs/$ARMPL_VERSION/$ARMPL_VARIANT
    module unload arm/gcc

    export INCS="$INCS -I$ARMPL_DIR/include"
    export LLIBS="$LLIBS -L$ARMPL_DIR/lib -larmpl"
fi



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

    # Unpack VASP source
    mkdir -p $CFG_DIR
    rm -rf "$CFG_DIR/vasp.5.4.4"
    tar xf vasp.5.4.4.tar.gz -C $CFG_DIR

    # Generate arch config file
    envsubst <$SCRIPT_DIR/../makefile.include.template >$SRC_DIR/makefile.include

    # Perform build
    cd $CFG_DIR/vasp.5.4.4
    if ! make std
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$SRC_DIR/bin/vasp_std" ]
    then
        echo "Executable '$SRC_DIR/bin/vasp_std' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    cd $CFG_DIR
    if [ ! -d vasp-test-suite ]
    then
        git clone $BENCHMARK_DIR
    fi

    cd $RUN_DIR
    bash $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
