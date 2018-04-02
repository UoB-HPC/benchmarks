#!/bin/bash

DIR="$PWD/OpenSBLI"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/Benchmark/OpenSBLI_ops.cpp" ]
then
    echo "Directory '$DIR' does not exist or does not contain setup.py"
    exit 1
fi

module swap craype-{broadwell,x86-skylake}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128
module load cray-hdf5-parallel

# Build OPS
export OPS_COMPILER=intel
export OPS_INSTALL_PATH=$PWD/OpenSBLI/OPS/ops
pushd $OPS_INSTALL_PATH/c
if ! make -B mpi MPICC=cc MPICXX=CC \
    CCFLAGS="-O3 -xCORE-AVX512 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div -std=c99" \
    CXXFLAGS="-O3 -xCORE-AVX512 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div" \
    MPIFLAGS="-O3 -xCORE-AVX512 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div -std=c99 "
then
    echo "Building OPS failed"
    exit 1
fi
popd

# Build OpenSBLI benchmark
cd $PWD/OpenSBLI/Benchmark
if ! make -B OpenSBLI_mpi \
    MPICPP=CC \
    CCFLAGS="-O3 -xCORE-AVX512 -fno-alias -finline -inline-forceinline -no-prec-div -fp-model strict -fp-model source -parallel"
then
    echo "Building OpenSBLI benchmark failed"
    exit 1
fi
mv OpenSBLI_mpi OpenSBLI_mpi_skl
