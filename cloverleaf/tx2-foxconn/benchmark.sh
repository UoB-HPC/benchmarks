#!/bin/bash

# Process arguments
if [ $# -lt 1 ]
then
    echo "Usage: ./benchmark.sh build|run|list [COMPILER]"
    exit 1
fi

ACTION=$1
COMPILER=${2:-cce-8.7}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`
PLATFORM=tx2-foxconn

EXE=clover_leaf
SRC_DIR=$PWD/CloverLeaf_ref
RUN_DIR=$PWD/CloverLeaf-$PLATFORM-$COMPILER


if [ "$ACTION" == "list" ]
then
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.2"
    echo "  gcc-8.1"
    echo "  arm-18.3"
    exit 0
fi


# Fetch source code if necessary
if [ ! -r "$SRC_DIR/clover.f90" ]
then
    if ! "$SCRIPT_DIR/../fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi
fi


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.0
        MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        ;;
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        module load openmpi/3.0.0/gcc-7.2
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpifort C_MPI_COMPILER=mpicc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        module load openmpi/3.0.0/gcc-8.1
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpifort C_MPI_COMPILER=mpicc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        module load openmpi/3.0.0/arm-18.3
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpifort C_MPI_COMPILER=mpicc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        ;;
    *)
        echo "Invalid compiler '$COMPILER' (use 'list' to show available options)"
        exit 1
        ;;
esac


# Handle actions
if [ "$ACTION" == "build" ]
then
    # Perform build
    rm -f $SRC_DIR/$EXE
    if ! eval make -C $SRC_DIR -B $MAKE_OPTS
    then
        echo "Build failed"
        exit 1
    fi

    mkdir -p $RUN_DIR
    mv $SRC_DIR/$EXE $RUN_DIR

elif [ "$ACTION" == "run" ]
then
    cd $RUN_DIR
    if [ ! -x "$EXE" ]
    then
        echo "Executable '$EXE' not found"
        exit 1
    fi

    # Run the benchmark
    cp $SRC_DIR/InputDecks/clover_bm16.in clover.in
    export OMP_PROC_BIND=true
    export OMP_NUM_THREADS=4
    mpirun -np 64 --bind-to core ./$EXE
else
    echo "Invalid action (use 'build' or 'run')"
    exit 1
fi
