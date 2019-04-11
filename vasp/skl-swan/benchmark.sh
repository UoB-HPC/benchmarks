#!/bin/bash

function setup_env()
{
    module swap craype-{broadwell,x86-skylake}
    PRGENV=`module -t list 2>&1 | grep PrgEnv`
    case "$COMPILER" in
        cce-8.7)
            module swap $PRGENV PrgEnv-cray
            module swap cce cce/8.7.9
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
            module swap $PRGENV PrgEnv-gnu
            module swap gcc gcc/7.3.0
            export FC=ftn
            export FCL=ftn
            export CC=gcc
            export CXX=g++
            export CPP="gcc -E -P -C -w"
            export OFLAG="-O3 -march=skylake-avx512"
            export FFLAGS="-w"
            export FREE="-ffree-form -ffree-line-length-none"
            MKL_COMP="gf"
            LIBSCI_COMP="gnu_71"
            ;;
        intel-2010)
            module swap $PRGENV PrgEnv-intel
            module swap intel intel/19.0.0.117
            export FC=ftn
            export FCL=ftn
            export CC=icc
            export CXX=icpc
            export CPP="fpp -f_com=no -free -w0"
            export OFLAG="-O3 -xCORE-AVX512"
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
        libsci-18.12.1)
            module swap cray-libsci cray-libsci/18.12.1
            # Make sure libsci gets linked before MKL
            export LLIBS="$LLIBS -lsci_${LIBSCI_COMP}_mp -lsci_${LIBSCI_COMP}_mpi_mp"
            ;;
        mkl-2019)
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
        cray-fftw-3.3.8)
            module load cray-fftw/3.3.8.2
            # Make sure fftw gets linked before MKL
            export LLIBS="$LLIBS -lfftw3 -lfftw3_threads"
            ;;
        mkl-2019)
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

        source /opt/intel/compilers_and_libraries_2019.0.117/linux/mkl/bin/mklvars.sh intel64
        export MKL_LIB=${MKLROOT}/lib/intel64
        export LLIBS="$LLIBS -L${MKL_LIB} -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_lp64"
    fi
}

SCRIPT="`realpath $0`"
export ARCH="skl"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="gcc-7.3 intel-2019 cce-8.7"
export BLASLIBS="mkl-2019 cray-libsci-18.12.1"
export FFTLIBS="mkl-2019 cray-fftw-3.3.8"
export DEFAULT_COMPILER=intel-2019
export DEFAULT_BLASLIB=mkl-2019
export DEFAULT_FFTLIB=mkl-2019
export PBS_RESOURCES=":ncpus=56"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
