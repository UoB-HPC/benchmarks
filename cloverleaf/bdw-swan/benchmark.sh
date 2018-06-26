#!/bin/bash

# Process arguments
if [ -z "$PBS_O_WORKDIR" ]
then
    if [ $# -lt 1 ]
    then
        echo "Usage: ./benchmark.sh build|run|list [COMPILER]"
        exit 1
    fi

    ACTION=$1
    COMPILER=${2:-intel-2018}
    SCRIPT=`realpath $0`
    SCRIPT_DIR=`realpath $(dirname $SCRIPT)`
    cd $SCRIPT_DIR

    if [ "$ACTION" == "list" ]
    then
        echo "Valid compilers:"
        echo "  cce-8.7"
        echo "  gcc-7.3"
        echo "  intel-2018"
        exit 0
    fi
else
    cd $PBS_O_WORKDIR
fi


EXE=clover_leaf
RUN_DIR=run-$COMPILER
SOURCE_DIR="$SCRIPT_DIR/../CloverLeaf_ref"
if [ ! -r "$SOURCE_DIR/clover.f90" ]
then
    echo "Directory '$SOURCE_DIR' does not exist or does not contain clover.f90"
    exit 1
fi


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        MAKE_OPTS='COMPILER=CRAY MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=broadwell -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=broadwell -funroll-loops"'
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_INTEL="-O3 -no-prec-div -xCORE-AVX2"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xCORE-AVX2"'
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
    rm -f $SOURCE_DIR/$EXE
    if ! eval make -C $SOURCE_DIR -B $MAKE_OPTS
    then
        echo "Build failed"
        exit 1
    fi

    mkdir -p $RUN_DIR
    mv $SOURCE_DIR/$EXE $RUN_DIR

elif [ "$ACTION" == "run" ]
then
    if [ -z "$PBS_O_WORKDIR" ]
    then
        # Submit this script as a job to run the benchmark
        qsub $SCRIPT \
            -q large -l nodes=1 -l walltime=00:15:00 -joe \
            -N cloverleaf -o $SCRIPT_DIR/$COMPILER.out \
            -vACTION="$ACTION",COMPILER="$COMPILER"
    else
        cd $RUN_DIR
        if [ ! -x "$EXE" ]
        then
            echo "Executable '$EXE' not found"
            exit 1
        fi

        # Run the benchmark
        cp $SOURCE_DIR/InputDecks/clover_bm16.in clover.in
        OMP_NUM_THREADS=1 aprun -n 44 -d 1 -j 1 ./$EXE
    fi
else
    echo "Invalid action (use 'build' or 'run')"
    exit 1
fi
