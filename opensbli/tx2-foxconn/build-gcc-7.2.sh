#!/bin/bash

module purge
module load gcc/7.2.0
module load openmpi/3.0.0/gcc-7.2
module load hdf5-parallel

EXE=OpenSBLI_mpi_gcc-7.2

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
export OPS_COMPILER=gnu
export OPS_INSTALL_PATH=$DIR/OPS/ops
export MPI_INSTALL_PATH=/lustre/projects/bristol/modules-arm/openmpi/3.0.0/gcc-7.2
pushd $OPS_INSTALL_PATH/c
if ! make -B mpi \
    HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2 \
    CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -mcpu=thunderx2t99 -ffp-contract=fast"
then
    echo "Building OPS failed"
    exit 1
fi
popd

# Build OpenSBLI benchmark
cd $DIR/Benchmark
if ! make -B OpenSBLI_mpi \
    HDF5_INSTALL_PATH=/lustre/projects/bristol/modules-arm/hdf5-parallel/1.10.1/gcc-7.2 \
    CCFLAGS="-O3 -fPIC -DUNIX -Wall -mcpu=thunderx2t99 -ffp-contract=fast"
then
    echo "Building OpenSBLI benchmark failed"
    exit 1
fi
mv OpenSBLI_mpi $EXE
