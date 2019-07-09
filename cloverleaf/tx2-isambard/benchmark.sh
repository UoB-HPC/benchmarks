#!/bin/bash

DEFAULT_COMPILER=cce-8.7
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.2"
    echo "  gcc-8.2"
    echo "  arm-18.3"
    echo "  arm-18.4"
    echo
    echo "Valid models:"
    echo " omp"
    echo " kokkos"
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

export BENCHMARK_EXE=clover_leaf
export CONFIG="tx2"_"$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/CloverLeaf-$CONFIG

# Set up the environment
module load craype-arm-thunderx2
case "$COMPILER" in
    cce-8.7)
        module load PrgEnv-cray
        module swap cce cce/8.7.9
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
    gcc-8.2)
        module swap PrgEnv-cray PrgEnv-gnu
        module swap gcc gcc/8.2.0
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        # export OMP_PROC_BIND=spread DON'T BIND ON A CRAY
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        module load openmpi/3.0.0/arm-18.3
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpifort C_MPI_COMPILER=mpicc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        ;;
    arm-18.4)
        module purge
        module load arm/hpc-compiler/18.4
        module load openmpi/3.0.0/arm-18.4
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=mpifort C_MPI_COMPILER=mpicc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
        ;;
    arm-19.0)
        module swap PrgEnv-cray PrgEnv-allinea
        module swap allinea allinea/19.0.0.1
        MAKE_OPTS='COMPILER=GNU MPI_COMPILER=ftn C_MPI_COMPILER=cc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -mcpu=thunderx2t99 -funroll-loops"'
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
    export SRC_DIR=$PWD/CloverLeaf_ref
    ;;
  kokkos)
    module load kokkos/2.8.0/$COMPILER
    export SRC_DIR=$PWD/cloverleaf_kokkos
    MAKE_OPTS="CXX=CC"
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

    qsub \
        -o CloverLeaf-$CONFIG.out \
        -N cloverleaf \
        -V \
        $SCRIPT_DIR/run.job \

else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
