#!/bin/bash

DEFAULT_COMPILER=gcc-8.2
DEFAULT_MODEL=omp3
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-8.2"
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
export COMPILER=${2:-$DEFAULT_COMPILER}
MODEL=${3:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export BENCHMARK_EXE=neutral."$MODEL"
export CONFIG="tx2"_"$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/neutral-$CONFIG

# Set up the environment
if [ -z "$CRAY_CPU_TARGET" ]; then
    module load craype-arm-thunderx2
else
    module swap "craype-$CRAY_CPU_TARGET" craype-arm-thunderx2
fi

# Set up the environment
case "$COMPILER" in
#    arm-19.0)
#       [ "$PE_ENV" != ALLINEA ] && module swap "PrgEnv-$(tr '[:upper:]' '[:lower:]' <<<"$PE_ENV")" PrgEnv-allinea
#        module swap allinea allinea/19.0.0.1
#        MAKE_OPTS='COMPILER=GNC ARCH_COMPILER_CC=cc ARCH_COMPILER_CPP=c++'
#        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GNU="-std=gnu99 -Wall -fopenmp -Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast"'
#        ;;
    cce-8.7)
        module load craype-arm-thunderx2
        module swap cce cce/8.7.9
        MAKE_OPTS='COMPILER=CRAY ARCH_COMPILER_CC=cc ARCH_COMPILER_CPP=c++'
        ;; 
    gcc-8.2)
        module swap PrgEnv-cray PrgEnv-gnu
        module swap gcc gcc/8.2.0
        MAKE_OPTS='COMPILER=GCC ARCH_COMPILER_CC=gcc ARCH_COMPILER_CPP=g++'
        MAKE_OPTS="$MAKE_OPTS"' CFLAGS_GCC="-std=gnu99 -Wall -fopenmp -Ofast -mcpu=thunderx2t99 -ffast-math -ffp-contract=fast"'
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
        module use /lustre/projects/bristol/modules-arm-phase2/modulefiles
        case "$COMPILER" in
#            arm-19.0)
#                module load kokkos/2.8.0/arm-19.0
#                ;;
            gcc-8.2)
                module load kokkos/2.8.0/gcc-8.2
                ;;
#            cce-8.7)
#                module load kokkos/2.8.0/cce-8.7
#                ;;
            *)
                echo "Kokkos not supported with compiler '$COMPILER'"
                exit 1
                ;;
        esac
        FETCH_FILE='fetch_kokkos.sh'
        export SRC_DIR=$PWD/neutral_kokkos
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
