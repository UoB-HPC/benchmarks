#!/bin/bash

# TODO: Option for libxsmm

DEFAULT_COMPILER=gcc-7.3
DEFAULT_BLASLIB=mkl-2018
DEFAULT_FFTLIB=cray-fftw-3.3.6
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [BLAS-LIB] [FFT-LIB]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.3"
    echo "  intel-2018"
    echo
    echo "Valid BLAS libraries:"
    echo "  mkl-2018"
    echo "  libsci-18.07"
    echo
    echo "Valid FFT libraries:"
    echo "  mkl-2018"
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

export CONFIG="skl"_"$COMPILER"_"$BLASLIB"_"$FFTLIB"
export SRC_DIR=$PWD/cp2k-5.1
export RUN_DIR=$PWD/cp2k-$CONFIG

# Set up the environment
module load craype-x86-skylake
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        export CC=cc
        export FC=ftn
        export LD=ftn
        export CFLAGS=""
        export FCFLAGS="-hfp2"
        MKL_COMP="gf"
        LIBSCI_COMP="cray"
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        export CC=cc
        export FC=ftn
        export LD=ftn
        export CFLAGS=""
        export FCFLAGS="-O3 -fopenmp -march=skylake-avx512 -funroll-loops -ffast-math -ftree-vectorize -ffree-form -ffree-line-length-512"
        MKL_COMP="gf"
        LIBSCI_COMP="gnu_71"
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.3.222
        export CC=cc
        export FC=ftn
        export LD=ftn
        export CFLAGS=""
        export FCFLAGS="-O3 -fopenmp -xCORE-AVX512 -heap-arrays -fpp -free -nofor_main"
        MKL_COMP="intel"
        LIBSCI_COMP="intel"
        ;;

    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

# Use dynamic linking to allow combining MKL with libsci/fftw
export LDFLAGS="$LDFLAGS -dynamic"

case "$BLASLIB" in
    libsci-18.07)
        module swap cray-libsci cray-libsci/18.07.1
        # Make sure libsci gets linked before MKL
        export LIBS="$LIBS -lsci_${LIBSCI_COMP}_mp -lsci_${LIBSCI_COMP}_mpi_mp"
        ;;
    mkl-2018)
        export FCFLAGS="$FCFLAGS "'-I${MKLROOT}/include'
        USE_MKL=1
        ;;
    *)
        echo
        echo "Invalid BLAS library '$BLASLIB'."
        usage
        exit 1
        ;;
esac

case "$FFTLIB" in
    cray-fftw-3.3.6)
        module load cray-fftw/3.3.6.5
        # Make sure fftw gets linked before MKL
        export LIBS="$LIBS -lfftw3 -lfftw3_threads"
        ;;
    mkl-2018)
        export FCFLAGS="$FCFLAGS "'-I${MKLROOT}/include/fftw'
        USE_MKL=1
        ;;
    *)
        echo
        echo "Invalid FFT library '$FFTLIB'."
        usage
        exit 1
        ;;
esac

# Add MKL flags last if used
if  [ "$USE_MKL" == "1" ]
then
    if [ -z "$MKL_COMP" ]
    then
        echo
        echo "Using MKL is not supported for $COMPILER."
        echo
        exit
    fi

    source /opt/intel/compilers_and_libraries_2018.3.222/linux/mkl/bin/mklvars.sh intel64
    export MKL_LIB=${MKLROOT}/lib/intel64
    export DFLAGS="${DFLAGS} -D__MKL"
    export LIBS="$LIBS -L${MKL_LIB} -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_lp64"
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

    # Generate arch config file
    envsubst <$SCRIPT_DIR/../template.psmp >$SRC_DIR/arch/$CONFIG.psmp

    # Perform build
    cd $SRC_DIR/makefiles
    make ARCH=$CONFIG VERSION=psmp clean
    if ! make ARCH=$CONFIG VERSION=psmp -j 16
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
    qsub $SCRIPT_DIR/run.job \
        -d $RUN_DIR \
        -o cp2k-$CONFIG.out \
        -N cp2k \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
