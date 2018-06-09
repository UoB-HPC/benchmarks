#!/bin/bash

module swap cce cce/8.7.0
module load hdf5-parallel

EXE=OpenSBLI_mpi_cce-8.7

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

# Build OPS
export OPS_COMPILER=cray
export OPS_INSTALL_PATH=$DIR/OPS/ops
pushd $OPS_INSTALL_PATH/c
if ! make -B mpi \
    HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2
then
    echo "Building OPS failed"
    exit 1
fi
popd

# Build OpenSBLI benchmark
cd $DIR/Benchmark
if ! make -B OpenSBLI_mpi \
    HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2
then
    echo "Building OpenSBLI benchmark failed"
    exit 1
fi
mv OpenSBLI_mpi $EXE
