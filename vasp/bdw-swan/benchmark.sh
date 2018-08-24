#!/bin/bash

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

export CONFIG="bdw"_"$COMPILER"_"$BLASLIB"_"$FFTLIB"
export CFG_DIR=$PWD/vasp-$CONFIG
export SRC_DIR=$CFG_DIR/vasp.5.4.4
export RUN_DIR=$CFG_DIR/vasp-test-suite/PdO/91
export BENCHMARK_DIR=$PWD/vasp-test-suite

# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        export FC=ftn
        export FCL=ftn
        export CC=cc
        export CXX=CC
        export CPP="cpp -E -P -w -traditional"
        export OFLAG="-O2"
        export FREE="-ffree"
        export FFLAGS="-dC -rmo -emEb -F noupcase -F backslash"
        MKL_COMP="gf"
        LIBSCI_COMP="cray"
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        export FC=ftn
        export FCL=ftn
        export CC=gcc
        export CXX=g++
        export CPP="gcc -E -P -C -w"
        export OFLAG="-O3 -march=broadwell"
        export FFLAGS="-w"
        export FREE="-ffree-form -ffree-line-length-none"
        MKL_COMP="gf"
        LIBSCI_COMP="gnu_71"
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        export FC=ftn
        export FCL=ftn
        export CC=icc
        export CXX=icpc
        export CPP="fpp -f_com=no -free -w0"
        export OFLAG="-O3 -xCORE-AVX2"
        export FFLAGS="-w"
        export FREE="-ffree-form -ffree-line-length-none"
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
export LLIBS="$LLIBS -dynamic"

case "$BLASLIB" in
    libsci-18.07)
        module swap cray-libsci cray-libsci/18.07.1
        # Make sure libsci gets linked before MKL
        export LLIBS="$LLIBS -lsci_${LIBSCI_COMP}_mp -lsci_${LIBSCI_COMP}_mpi_mp"
        ;;
    mkl-2018)
        export FFLAGS="$FFLAGS "'-I${MKLROOT}/include'
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
        export LLIBS="$LLIBS -lfftw3 -lfftw3_threads"
        ;;
    mkl-2018)
        export FFLAGS="$FFLAGS "'-I${MKLROOT}/include/fftw'
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

    source /opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/bin/mklvars.sh intel64
    export MKL_LIB=${MKLROOT}/lib/intel64
    export LLIBS="$LLIBS -L${MKL_LIB} -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_lp64"
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

    qsub $SCRIPT_DIR/run.job \
        -d $RUN_DIR \
        -o $CFG_DIR/vasp-$CONFIG.out \
        -N vasp \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
