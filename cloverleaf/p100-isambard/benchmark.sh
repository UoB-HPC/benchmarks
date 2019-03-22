#!/bin/bash

set -eu

DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [MODEL]"
    echo
    echo "Valid models:"
    echo "  omp-target"
    echo "  cuda"
    echo " kokkos"
    echo
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
export MODEL=${2:-$DEFAULT_MODEL}
SCRIPT=`basename $0`
SCRIPT_DIR=`dirname $0`
export BENCHMARK_EXE=clover_leaf

case "$MODEL" in
    omp-target)
        module swap "craype-$CRAY_CPU_TARGET" craype-broadwell
        module load craype-accel-nvidia60
        export SRC_DIR="$PWD/CloverLeaf-OpenMP4"
        MAKE_OPTS='-j16 COMPILER=CRAY MPI_F90=ftn MPI_C=cc'
        ;;
    cuda)
        module swap "craype-$CRAY_CPU_TARGET" craype-broadwell
        module load craype-accel-nvidia60
        export SRC_DIR="$PWD/CloverLeaf_CUDA"
        MAKE_OPTS='-j16 COMPILER=CRAY NV_ARCH=PASCAL C_MPI_COMPILER=cc MPI_COMPILER=ftn'
        ;;
    kokkos)
        module swap "craype-$CRAY_CPU_TARGET" craype-broadwell
        module load craype-accel-nvidia60
        module unload cudatoolkit/8.0.44
        module load kokkos/pascal
        module load gcc/6.1.0
        module load openmpi/gcc-6.1.0/1.10.7
        export SRC_DIR="$PWD/CloverLeaf"
        MAKE_OPTS="COMPILER=GNU USE_KOKKOS=gpu KOKKOS_PATH=$KOKKOS_PATH"
        ;;
    *)
        echo
        echo "Invalid model '$MODEL'."
        usage
        exit 1
        ;;
esac

export CONFIG="p100_$MODEL"
export RUN_DIR="$PWD/CloverLeaf-$CONFIG"

# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! eval "$SCRIPT_DIR/../fetch.sh $MODEL"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    if [ "$MODEL" != "kokkos" ]
    then
        # As of 21 Mar 2019, the linker command does not work with the Cray compiler (and possibly others too)
        sed -i '/-o clover_leaf/c\\t$(MPI_F90) $(FFLAGS) $(OBJ) $(LDLIBS) -o clover_leaf' "$SRC_DIR/Makefile"
    fi

    # Perform build
    rm -f "$SRC_DIR/$BENCHMARK_EXE" "$RUN_DIR/$BENCHMARK_EXE"
    make -C "$SRC_DIR" clean
    if ! eval make -C "$SRC_DIR" -B "$MAKE_OPTS"
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

    qsub -N CloverLeaf-$CONFIG \
         -o "CloverLeaf-$CONFIG.out" \
         -V \
         "$SCRIPT_DIR/run.job"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
