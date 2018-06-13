#!/bin/bash

DIR="$PWD/../OpenSBLI"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/Benchmark/OpenSBLI_ops.cpp" ]
then
    echo "Directory '$DIR' does not exist or does not contain Benchmark/OpenSBLI_ops.cpp"
    exit 1
fi


module swap PrgEnv-{cray,gnu}
module swap gcc gcc/7.3.0
module load cray-hdf5-parallel

EXE=OpenSBLI_mpi_bdw_gcc-7.3


# Build OPS
export OPS_COMPILER=gnu
export OPS_INSTALL_PATH=$DIR/OPS/ops
pushd $OPS_INSTALL_PATH/c
if ! make -B mpi MPICC=cc MPICXX=CC \
    CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -march=broadwell -ffp-contract=fast"
then
    echo "Building OPS failed"
    exit 1
fi
popd

# Build OpenSBLI benchmark
cd $DIR/Benchmark
if ! make -B OpenSBLI_mpi \
    MPICPP=CC \
    CCFLAGS="-O3 -fPIC -DUNIX -Wall -march=broadwell -ffp-contract=fast"
then
    echo "Building OpenSBLI benchmark failed"
    exit 1
fi
mv OpenSBLI_mpi $EXE
