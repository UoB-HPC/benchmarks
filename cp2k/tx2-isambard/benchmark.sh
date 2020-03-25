#!/bin/bash

DEFAULT_COMPILER=gcc-8.3
DEFAULT_BLASLIB=armpl-19.2
DEFAULT_FFTLIB=cray-fftw-3.3.8
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [BLAS-LIB] [FFT-LIB]"
    echo
    echo "Valid compilers:"
    echo "  gcc-8.3"
    echo
    echo "Valid BLAS libraries:"
    echo "  armpl-19.2"
    echo
    echo "Valid FFT libraries:"
    echo "  cray-fftw-3.3.8"
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
export SRC_DIR=$PWD/cp2k-5.1
export RUN_DIR=$PWD/cp2k-$CONFIG

# Set up the environment
PRGENV=`module -t list 2>&1 | grep PrgEnv`
case "$COMPILER" in
    gcc-8.3)
        module load cdt/19.08
        module swap $PRGENV PrgEnv-gnu
        module swap gcc gcc/8.3.0
        export CC=cc
        export FC=ftn
        export LD=ftn
        export CFLAGS="-Ofast -mcpu=thunderx2t99"
        export FCFLAGS="-O3 -fopenmp -mcpu=thunderx2t99 -ffast-math -funroll-loops -ffp-contract=fast"
        export FCFLAGS="$FCFLAGS -march=armv8.1-a -mcpu=native -ftree-vectorize -ffree-form -ffree-line-length-512"
        ARMPL_VARIANT=gcc-8.3
        ;;
    gcc-9.2)
        module load cdt/19.08
        module swap $PRGENV PrgEnv-gnu
        module use /lustre/home/br-hwaugh/installations/arm-20/modulefiles
        module load Generic-AArch64/SUSE/12/gcc-9.2.0/armpl/20.0.0
        export CC=cc
        export FC=ftn
        export LD=ftn
        export CFLAGS="-Ofast -mcpu=thunderx2t99"
        export FCFLAGS="-O3 -fopenmp -mcpu=thunderx2t99 -ffast-math -funroll-loops -ffp-contract=fast"
        export FCFLAGS="$FCFLAGS -march=armv8.1-a -mcpu=native -ftree-vectorize -ffree-form -ffree-line-length-512"
        ARMPL_VARIANT=gcc-9.2
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac


case "$FFTLIB" in
    cray-fftw-3.3.8)
        export FCFLAGS="$FCFLAGS -I/opt/cray/pe/fftw/3.3.8.3/arm_thunderx2/include"
        export LDFLAGS="$LDFLAGS -L/opt/cray/pe/fftw/3.3.8.3/arm_thunderx2/lib"
        export LIBS="$LIBS -L/opt/cray/pe/fftw/3.3.8.3/arm_thunderx2/lib"
        export LIBS="$LIBS -lfftw3 -lfftw3_omp"
        ;;
    *)
        echo
        echo "Invalid FFT library '$FFTLIB'."
        usage
        exit 1
        ;;
esac

case "$BLASLIB" in
    armpl-19.2)
        export LD_LIBRARY_PATH=/opt/allinea/19.2.0.0/opt/arm/armpl-19.2.0_ThunderX2CN99_SUSE-12_gcc_8.2.0_aarch64-linux/lib:$LD_LIBRARY_PATH
        export LIBS="$LIBS -L/opt/allinea/19.2.0.0/opt/arm/armpl-19.2.0_ThunderX2CN99_SUSE-12_gcc_8.2.0_aarch64-linux/lib"
        export LIBS="$LIBS -larmpl_lp64_mp -lamath"
        ARMPL_VERSION=19.2
        ;;
    *)
        echo
        echo "Invalid BLAS library '$BLASLIB'."
        usage
        exit 1
        ;;
esac
# # Add ARMPL flags last if used
#if [ -n "$ARMPL_VERSION" ]
#then
#    if [ -z "$ARMPL_VARIANT" ]
#    then
#        echo
#        echo "Using armpl is not supported for $COMPILER."
#        echo
#        exit 1
#    fi
#    module load arm/perf-libs/$ARMPL_VERSION/$ARMPL_VARIANT
#    module unload arm/gcc
#    export FCFLAGS="$FCFLAGS -I$ARMPL_DIR/include"
#    export LIBS="$LIBS -larmpl"
#fi



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
    qsub -v SRC_DIR,CONFIG $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
