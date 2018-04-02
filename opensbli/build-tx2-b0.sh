#!/bin/bash

DIR="$PWD/OpenSBLI"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/Benchmark/OpenSBLI_ops.cpp" ]
then
    echo "Directory '$DIR' does not exist or does not contain Benchmark/OpenSBLI_ops.cpp"
    exit 1
fi

module load hdf5-parallel

# Build OPS
export OPS_COMPILER=cray
export OPS_INSTALL_PATH=$PWD/OpenSBLI/OPS/ops
pushd $OPS_INSTALL_PATH/c
if ! make -B mpi \
    HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2
then
    echo "Building OPS failed"
    exit 1
fi
popd

# Build OpenSBLI benchmark
cd $PWD/OpenSBLI/Benchmark
if ! make -B OpenSBLI_mpi \
    HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2
then
    echo "Building OpenSBLI benchmark failed"
    exit 1
fi
mv OpenSBLI_mpi OpenSBLI_mpi_tx2
