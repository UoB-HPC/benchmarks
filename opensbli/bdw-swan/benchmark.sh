#!/bin/bash

DEFAULT_COMPILER=cce-8.7
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.3"
    echo "  intel-2018"
    echo
    echo "The default configuration is '$DEFAULT_COMPILER'."
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
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export BENCHMARK_EXE=OpenSBLI_mpi
export CONFIG="bdw"_"$COMPILER"
export SRC_DIR=$PWD/OpenSBLI
export RUN_DIR=$PWD/OpenSBLI-$CONFIG

export OPS_INSTALL_PATH=$SRC_DIR/OPS/ops


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        module load cray-hdf5-parallel
        export OPS_COMPILER=cray
        OPS_MAKE_OPTS='MPICC=cc MPICXX=CC'
        SBLI_MAKE_OPTS=''
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        module load cray-hdf5-parallel
        export OPS_COMPILER=gnu
        OPS_MAKE_OPTS='MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -march=broadwell -ffp-contract=fast"'
        SBLI_MAKE_OPTS='MPICPP=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -march=broadwell -ffp-contract=fast"'
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        module load cray-hdf5-parallel
        export OPS_COMPILER=intel
        OPS_MAKE_OPTS='MPICC=cc MPICXX=CC CXXFLAGS="-O3 -xCORE-AVX2 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div"'
        OPS_MAKE_OPTS=$OPS_MAKE_OPTS' MPIFLAGS="-O3 -xCORE-AVX2 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div -std=c99"'
        SBLI_MAKE_OPTS='MPICPP=CC CCFLAGS="-O3 -xCORE-AVX2 -fno-alias -finline -inline-forceinline -no-prec-div -fp-model strict -fp-model source -parallel"'
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
    if ! "$SCRIPT_DIR/../fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    rm -f $SRC_DIR/Benchmark/$BENCHMARK_EXE $RUN_DIR/$BENCHMARK_EXE

    # Build OPS
    if ! eval make -C $SRC_DIR/OPS/ops/c -B mpi $OPS_MAKE_OPTS
    then
        echo
        echo "OPS build failed."
        echo
        exit 1
    fi

    # Build the benchmark
    if ! eval make -C $SRC_DIR/Benchmark -B OpenSBLI_mpi $SBLI_MAKE_OPTS
    then
        echo
        echo "OpenSBLI build failed."
        echo
        exit 1
    fi

    mkdir -p $RUN_DIR
    mv $SRC_DIR/Benchmark/$BENCHMARK_EXE $RUN_DIR

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
        -o opensbli-$CONFIG.out \
        -N opensbli \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
