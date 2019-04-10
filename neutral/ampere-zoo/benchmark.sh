#!/bin/bash

DEFAULT_COMPILER=gcc-8.1
DEFAULT_MODEL=omp3
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  gcc-8.1"
    echo "  llvm-trunk"
    echo "  pgi-18"
    echo
    echo "Valid models:"
    echo "   omp3"
    echo "   kokkos"
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
export CONFIG="ampere"_"$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/neutral-$CONFIG


# Set up the environment
case "$COMPILER" in
    gcc-8.1)
        module purge
        module load gcc/8.1
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -march=armv8-a -ffast-math -ffp-contract=fast"'
        ;;
    llvm-trunk)
        module purge
        module load llvm/trunk
	MAKE_OPTS='COMPILER=CLANG ARCH_COMPILER_CC=clang ARCH_COMPILER_CPP=clang++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_CLANG="-std=gnu99 -Wall -fopenmp -Ofast -march=armv8-a -ffast-math -ffp-contract=fast"'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

case "$MODEL" in 
    omp3)
        FETCH_FILE='fetch.sh'
        export SRC_DIR=$PWD/arch/neutral
        ;;
    kokkos)
        FETCH_FILE='fetch_kokkos.sh'
        export SRC_DIR=$PWD/neutral_kokkos

	case "$COMPILER" in 
	    gcc-8.1)
		    module load kokkos/gcc-8.1
		    ;;
            llvm-trunk)
		    module load kokkos/clang
		    ;;
	     *)
		    echo
		    echo "Must use gcc-8.1 or llvm-trunk with Kokkos"
		    echo
		    exit
		    ;;
        esac
        ;;
    *)
        echo
        echo "Invalid model '$MODEL'."
        usage
        exit 1
        ;;
esac


# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! "$SCRIPT_DIR/../$FETCH_FILE"
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
