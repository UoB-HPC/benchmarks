#!/bin/bash

DIR="$PWD/../gromacs-2018.1"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/CMakeLists.txt" ]
then
    echo "Directory '$DIR' does not exist or does not contain CMakeLists.txt"
    exit 1
fi

module purge
module load arm/hpc-compiler/18.3
module load cmake

BUILD=$PWD/arm-18.3-fftw/build
rm -rf $BUILD
mkdir -p $BUILD
cd $BUILD
if ! cmake $DIR -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=armclang -DCMAKE_CXX_COMPILER=armclang++ \
    -DGMX_MPI=OFF -DGMX_GPU=OFF \
    -DGMX_CYCLE_SUBCOUNTERS=ON \
    -DFFTWF_LIBRARY=/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/lib/libfftw3f.a \
    -DFFTWF_INCLUDE_DIR=/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/include
then
    echo "Running cmake failed"
    exit 1
fi

if ! make -j 256
then
    echo "Building failed"
    exit 1
fi
