#!/bin/bash

DEFAULT_COMPILER=gcc-8.2
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  arm-19.0"
    echo "  cce-8.7"
    echo "  gcc-8.2"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  kokkos"
    echo
    echo "The default compiler is '$DEFAULT_COMPILER'."
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
SCRIPT_DIR=`realpath "$(dirname $SCRIPT)"`

export CONFIG="tx2_${COMPILER}_${MODEL}"
export RUN_DIR="$PWD/TeaLeaf-$CONFIG"

# Set up the environment
if [ -z "$CRAY_CPU_TARGET" ]; then
    module load craype-arm-thunderx2
else
    module swap "craype-$CRAY_CPU_TARGET" craype-arm-thunderx2
fi
case "$COMPILER" in
    arm-19.0)
        [ "$PE_ENV" != ALLINEA ] && module swap "PrgEnv-$(tr '[:upper:]' '[:lower:]' <<<"$PE_ENV")" PrgEnv-allinea
        module swap allinea allinea/19.0.0.1
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops -cpp -ffree-line-length-none"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        ;;
    cce-8.7)
        [ "$PE_ENV" != CRAY ] && module swap "PrgEnv-$(tr '[:upper:]' '[:lower:]' <<<"$PE_ENV")" PrgEnv-cray
        module swap cce cce/8.7.9
        MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        ;;
    gcc-8.2)
        [ "$PE_ENV" != GNU ] && module swap "PrgEnv-$(tr '[:upper:]' '[:lower:]' <<<"$PE_ENV")" PrgEnv-gnu
        module swap gcc gcc/8.2.0
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops -cpp -ffree-line-length-none"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

case "$MODEL" in
    omp)
        export SRC_DIR=$PWD/TeaLeaf_ref
        export BENCHMARK_EXE=tea_leaf
        ;;
    kokkos)
        module use /lustre/projects/bristol/modules-arm-phase2/modulefiles
        case "$COMPILER" in
            arm-*)
                module load kokkos/2.8.0/arm-19.0
                MAKE_OPTS="CC=armclang CPP=armclang++ OPTIONS='-DNO_MPI -march=armv8.1-a -mcpu=thunderx2t99'"
                ;;
            gcc-*)
                module load kokkos/2.8.0/gcc-8.2
                MAKE_OPTS='OPTIONS=-DNO_MPI'
                ;;
            cce-*)
                module load kokkos/2.8.0/cce-8.7
                MAKE_OPTS="COMPILER=CRAY CC=cc CPP=CC OPTIONS='-DNO_MPI -I${KOKKOS_PATH}/include'"
                ;;
            *)
                echo "Kokkos not supported with compiler '$COMPILER'"
                exit 1
                ;;
        esac

        export SRC_DIR=$PWD/TeaLeaf/2d
        export BENCHMARK_EXE=tealeaf
        MAKE_OPTS+=' KERNELS=kokkos '
        ;;
    *)
        echo
        echo "Invalid model '$MODEL'."
        usage
        exit 2
        ;;
esac


# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! "$SCRIPT_DIR/../fetch.sh" "$MODEL"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    # Perform build
    rm -f $SRC_DIR/$BENCHMARK_EXE $RUN_DIR/$BENCHMARK_EXE
    make -C "$SRC_DIR" clean
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

    if [ "$MODEL" = kokkos ]; then
        cp $SRC_DIR/tea.problems $RUN_DIR
        echo "4000 4000 10 9.5462351582214282e+01" >> "$RUN_DIR/tea.problems"
    fi

    cd $RUN_DIR || exit 1
    qsub -N "TeaLeaf-$MODEL" -o "TeaLeaf-$CONFIG.out" -V "$SCRIPT_DIR/run.job"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
