#!/bin/bash

DEFAULT_COMPILER=cce-8.7
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.2"
    echo "  gcc-8.1"
    echo "  arm-18.3"
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
export CONFIG="tx2"_"$COMPILER"
export SRC_DIR=$PWD/OpenSBLI
export RUN_DIR=$PWD/OpenSBLI-$CONFIG

export OPS_INSTALL_PATH=$SRC_DIR/OPS/ops


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.0
        module load hdf5-parallel
        export HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2
        export OPS_COMPILER=cray
        OPS_MAKE_OPTS=''
        SBLI_MAKE_OPTS=''
        ;;
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        module load openmpi/3.0.0/gcc-7.2
        module load hdf5-parallel
        export MPI_INSTALL_PATH=/lustre/projects/bristol/modules-arm/openmpi/3.0.0/gcc-7.2
        export HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2
        export OPS_COMPILER=gnu
        OPS_MAKE_OPTS='CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=thunderx2t99 -ffp-contract=fast"'
        SBLI_MAKE_OPTS='CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
        ;;
    gcc-8.1)
        module purge
        module load gcc/8.1.0
        module load openmpi/3.0.0/gcc-8.1
        module load hdf5-parallel
        export MPI_INSTALL_PATH=/lustre/projects/bristol/modules-arm/openmpi/3.0.0/gcc-8.1
        export HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2
        export OPS_COMPILER=gnu
        OPS_MAKE_OPTS='CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=thunderx2t99 -ffp-contract=fast"'
        SBLI_MAKE_OPTS='CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        module load openmpi/3.0.0/arm-18.3
        module load hdf5-parallel
        export MPI_INSTALL_PATH=/lustre/projects/bristol/modules-arm/openmpi/3.0.0/arm-18.3
        export HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2
        export OPS_COMPILER=gnu
        OPS_MAKE_OPTS='CC=armclang CXX=armclang++ CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=thunderx2t99 -ffp-contract=fast"'
        SBLI_MAKE_OPTS='CC=armclang CXX=armclang++ CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"'
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

    cd $RUN_DIR
    bash $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
