#!/bin/bash

function setup_env()
{
    export INCS=""
    export LLIBS=""
    ARMPL_VERSION=""

    PRGENV=`module -t list 2>&1 | grep PrgEnv`
    case "$COMPILER" in
        gcc-7.3)
            module load cdt/19.08
            module swap $PRGENV PrgEnv-gnu
            module swap gcc gcc/7.3.0
            export FC=ftn
            export FCL=ftn
            export CC=cc
            export CXX=CC
            export CPP="gcc -E -P -C -w"
            export OFLAG="-O3 -mcpu=thunderx2t99 -ffp-contract=fast -ffast-math"
            export FFLAGS="-w"
            export FREE="-ffree-form -ffree-line-length-none"
            ARMPL_VARIANT=gcc_8.2.0
            LIBSCI_COMP="gnu_73"
            ;;
        arm-19.2)
            module load cdt/19.08
            module swap $PRGENV PrgEnv-allinea
            module swap allinea allinea/19.2.0.0
            export FC=ftn
            export FCL=ftn
            export CC=cc
            export CXX=CC
            export CPP="gcc -E -P -C -w"
            export OFLAG="-O3 -mcpu=native -ffp-contract=fast -ffast-math"
            export FFLAGS="-w"
            export FREE="-ffree-form -ffree-line-length-none"
            ARMPL_VARIANT=arm-hpc-compiler_19.2
            LIBSCI_COMP="allinea"
            ;;
        cce-9.0)
            module load cdt/19.08
            module swap $PRGENV PrgEnv-cray
            module swap cce cce/9.0.1
            export FC=ftn
            export FCL=ftn
            export CC=cc
            export CXX=CC
            export CPP="cpp -E -P -w -traditional"
            export OFLAG="-O2"
            export FREE="-ffree"
            export FFLAGS="-dC -rmo -emEb -F noupcase -F backslash"
            LIBSCI_COMP="cray"
            ;;
        *)
            echo
            echo "Invalid compiler '$COMPILER'."
            usage
            exit 1
            ;;
    esac

    case "$BLASLIB" in
        armpl-19.2)
            ARMPL_VERSION=19.2
            ;;
        cray-libsci-19.06.1)
            module swap cray-libsci cray-libsci/19.06.1
            # TODO ???
            # Make sure libsci gets linked before ArmPL
            export LLIBS="$LLIBS -lsci_${LIBSCI_COMP}_mp -lsci_${LIBSCI_COMP}_mpi_mp"
            ;;
        *)
            echo
            echo "Invalid BLAS library '$BLASLIB'."
            usage
            exit 1
            ;;
    esac

    case "$FFTLIB" in
        armpl-19.2)
            if [ -n "$ARMPL_VERSION" -a "$ARMPL_VERSION" != "19.2" ]
            then
                echo "Arm PL version mismatch"
                exit 1
            fi
            ARMPL_VERSION=19.2
            ;;
        cray-fftw-3.3.8)
            export INCS="$INCS -I/opt/cray/pe/fftw/3.3.8.3/arm_thunderx2/include"
            export LLIBS="$LLIBS -L/opt/cray/pe/fftw/3.3.8.3/arm_thunderx2/lib -lfftw3"
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
        ARMPL_DIR=/opt/allinea/19.2.0.0/opt/arm/armpl-19.2.0_ThunderX2CN99_SUSE-12_${ARMPL_VARIANT}_aarch64-linux
        export INCS="$INCS -I$ARMPL_DIR/include"
        export LLIBS="$LLIBS -L$ARMPL_DIR/lib -larmpl"
        export LD_LIBRARY_PATH="$ARMPL_DIR/lib:$LD_LIBRARY_PATH"
    fi
}

SCRIPT="`realpath $0`"
export ARCH="tx2"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="gcc-7.3 arm-19.2 cce-9.0"
export BLASLIBS="armpl-19.2 cray-libsci-19.06.1"
export FFTLIBS="armpl-19.2 cray-fftw-3.3.8"
export DEFAULT_COMPILER=gcc-7.3
export DEFAULT_BLASLIB=cray-libsci-19.06.1
export DEFAULT_FFTLIB=cray-fftw-3.3.8
export PBS_RESOURCES=":ncpus=64"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
