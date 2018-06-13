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


module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128
module load cray-hdf5-parallel

EXE=OpenSBLI_mpi_bdw_intel-2018


# Build OPS
export OPS_COMPILER=intel
export OPS_INSTALL_PATH=$DIR/OPS/ops
pushd $OPS_INSTALL_PATH/c
if ! make -B mpi MPICC=cc MPICXX=CC \
    CCFLAGS="-O3 -xCORE-AVX2 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div -std=c99" \
    CXXFLAGS="-O3 -xCORE-AVX2 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div" \
    MPIFLAGS="-O3 -xCORE-AVX2 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div -std=c99 "
then
    echo "Building OPS failed"
    exit 1
fi
popd

# Build OpenSBLI benchmark
cd $DIR/Benchmark
if ! make -B OpenSBLI_mpi \
    MPICPP=CC \
    CCFLAGS="-O3 -xCORE-AVX2 -fno-alias -finline -inline-forceinline -no-prec-div -fp-model strict -fp-model source -parallel"
then
    echo "Building OpenSBLI benchmark failed"
    exit 1
fi
mv OpenSBLI_mpi $EXE
