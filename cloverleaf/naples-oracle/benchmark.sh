#!/bin/bash

set -e

DEFAULT_COMPILER=gcc-8.1
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  gcc-7.3"
    echo "  gcc-8.1"
    echo "  gcc-9.1"
    echo "  intel-2019"
    echo "  pgi-18"
    echo
    echo "Valid models:"
    echo "  mpi"
    echo "  omp"
    echo "  acc"
    echo "  kokkos"
    echo
    echo "The default configuration is '$DEFAULT_COMPILER $DEFAULT_MODEL'."
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
export MODEL=${3:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export BENCHMARK_EXE=clover_leaf
export CONFIG="naples"_"$COMPILER"_"$MODEL"
export SRC_DIR=$PWD/CloverLeaf_ref
export RUN_DIR=$PWD/CloverLeaf-$CONFIG


# Set up the environment
module purge

module use /mnt/shared/software/modulefiles

case "$COMPILER" in
    gcc-7.3)
        module load openmpi/3.0.3/gcc-7.3
        MAKE_OPTS='COMPILER=GNU'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=znver1 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=znver1 -funroll-loops"'
        ;;
    gcc-8.1)
        module load gcc/8.1.0
        module load openmpi/3.0.3/gcc81
        MAKE_OPTS='COMPILER=GNU'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=znver1 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=znver1 -funroll-loops"'
        ;;
    gcc-9.1)
        module load gcc/9.1.0
        module load openmpi/3.0.3/gcc91
        MAKE_OPTS='COMPILER=GNU'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=znver1 -funroll-loops"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_GNU="-Ofast -ffast-math -ffp-contract=fast -march=znver1 -funroll-loops"'
        ;;
    intel-2019)
        module load intel/compiler/2019.2
        module load intel/mpi/2019.2
        source /opt/intel/impi/2019.2.187/intel64/bin/mpivars.sh
        MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=mpiifort C_MPI_COMPILER=mpiicc'
        MAKE_OPTS=$MAKE_OPTS' FLAGS_INTEL="-O3 -no-prec-div -xhost"'
        MAKE_OPTS=$MAKE_OPTS' CFLAGS_INTEL="-O3 -no-prec-div -restrict -fno-alias -xhost"'
        MAKE_OPTS=$MAKE_OPTS' OMP_INTEL="-qopenmp"'
        ;;
    pgi-18)
	module load pgi/18.10
	export PATH=/opt/modules/pgi/linux86-64/18.10/mpi/openmpi/bin/:$PATH
	MAKE_OPTS='COMPILER=PGI'
	;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

case "$MODEL" in
    acc)
        export SRC_DIR=$PWD/CloverLeaf-OpenACC
        MAKE_OPTS=$MAKE_OPTS' FLAGS_PGI="-O3 -Mpreprocess -fast -acc -ta=multicore -tp=zen" CFLAGS_PGI="-O3 -ta=multicore -tp=zen" OMP_PGI=""'
        ;;
    kokkos)
        case "$COMPILER" in
          gcc-8.1)
            module load kokkos/2.8.00/gcc81
            ;;
          gcc-9.1)
            module load kokkos/2.8.00/gcc91
            ;;
        esac
        export SRC_DIR=$PWD/cloverleaf_kokkos
        MAKE_OPTS="-j"
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

    cd "$RUN_DIR"
    sbatch "$SCRIPT_DIR"/run.sh
    #bash "$SCRIPT_DIR"/run.sh
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
