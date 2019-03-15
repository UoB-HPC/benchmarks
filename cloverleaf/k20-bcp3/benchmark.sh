#!/bin/bash

DEFAULT_COMPILER=clang
DEFAULT_MODEL=omp-target
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  clang-9"
    echo
    echo "Valid models:"
    echo "  omp-target"
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
SCRIPT=`basename $0`
SCRIPT_DIR=`dirname $0`

export BENCHMARK_EXE=clover_leaf
export CONFIG="k20"_"$COMPILER"
export SRC_DIR=$PWD/CloverLeaf-OpenMP4
export RUN_DIR=$PWD/CloverLeaf-$CONFIG


# Set up the environment
case "$COMPILER" in
    clang-9)
        module use /newhome/pa13269/modules/modulefiles
        module load llvm
        module load openmpi3-gcc4.8
        export MAKEFLAGS='-j16'

        export OMPI_MPICC=clang
        export OMPI_FC=gfortran

        # TODO: there are most likely extraneous flags here
        # Flags for clang
        export CFLAGS="\
            -O3 -DOFFLOAD -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_35 \
            -I/newhome/pa13269/modules/install/llvm/include -L/newhome/pa13269/modules/install/llvm/lib \
            -lomptarget -lomp -lpthread -lgfortran -pthread -Wl,-rpath -Wl,/newhome/pa13269/modules/openmpi3-gcc4.8/lib \
            -Wl,--enable-new-dtags -L/newhome/pa13269/modules/openmpi3-gcc4.8/lib -lmpi"
        # Flags for gfortran
        export FLAGS="\
        -O3 -DOFFLOAD -L/newhome/pa13269/modules/openmpi3-gcc4.8/lib -L/cm/shared/languages/GCC-4.8.4/lib \
        -I/newhome/pa13269/modules/install/llvm/include -L/newhome/pa13269/modules/install/llvm/lib \
        -lomptarget -lomp -lpthread -lgfortran -pthread -I/newhome/pa13269/modules/openmpi3-gcc4.8/lib -Wl,-rpath \
        -Wl,/newhome/pa13269/modules/openmpi3-gcc4.8/lib -Wl,--enable-new-dtags \
        -L/newhome/pa13269/modules/openmpi3-gcc4.8/lib -lmpi_usempi -lmpi_mpifh -lmpi"

        MAKE_OPTS='\
          COMPILER=CLANG MPI_C=mpicc MPI_F90=mpif90 CFLAGS="${CFLAGS}" FLAGS="${FLAGS}'
        export COMPILER=clang
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac


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

    qsub $SCRIPT_DIR/run.job \
        -d $RUN_DIR \
        -o CloverLeaf-$CONFIG.out \
        -N cloverleaf \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
