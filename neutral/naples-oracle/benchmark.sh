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
    echo "  gcc-9.1"
    echo "  intel-2019"
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
export CONFIG="naples"_"$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/neutral-$CONFIG

module use /mnt/shared/software/modulefiles
# Set up the environment
case "$COMPILER" in
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -march=znver1 -ffast-math -ffp-contract=fast"'
        ;;
    gcc-9.1)
        module purge
        module load gcc/9.1.0
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -march=znver1 -ffast-math -ffp-contract=fast"'
        ;;
    pgi-18)
        module purge
        module load gcc/8.1
        module load pgi/18.10 
        MAKE_OPTS='COMPILER=PGI ARCH_COMPILER_CC=pgcc ARCH_COMPILER_CPP=gpc++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_PGI=" -fast -mp -ta=multicore -tp=zen"'
        echo 
	echo "Warning: Very long runtime for this compiler choice"
	echo 
	;;
    intel-2019)
        module purge
        module load intel/compiler/2019.2
	MAKE_OPTS='COMPILER=INTEL ARCH_COMPILER_CC=icc ARCH_COMPILER_CPP=icc'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_INTEL="-O3 -qopenmp -std=gnu99"'
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
		    module load kokkos/2.8.00/gcc81
		    ;;
	    gcc-9.1)
		    module load kokkos/2.8.00/gcc91
		    ;;
            intel-2019)
		    module load kokkos/intel-2019
		    ;;
	     *)
		    echo
		    echo "Must use gcc-8.1 or intel-2019 with Kokkos"
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
    #bash $SCRIPT_DIR/run.job
    sbatch $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
