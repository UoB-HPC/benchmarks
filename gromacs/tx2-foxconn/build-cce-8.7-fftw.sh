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

module swap cce cce/8.7.0
module load cmake

BUILD=$PWD/cce-8.7-fftw/build
rm -rf $BUILD
mkdir -p $BUILD
cd $BUILD
if ! cmake $DIR -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC \
    -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" \
    -DGMX_MPI=OFF -DGMX_GPU=OFF \
    -DGMX_CYCLE_SUBCOUNTERS=ON \
    -DFFTWF_LIBRARY=/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/lib/libfftw3f.a \
    -DFFTWF_INCLUDE_DIR=/opt/cray/pe/fftw/3.3.6.3/arm_thunderx2/include
then
    echo "Running cmake failed"
    exit 1
fi

# TODO: Proper fix for this (CMake generates "-l -lm" in link flags)
find . -name link.txt -exec sed -i 's/-l  -lm/-lm/g' {} \;

if ! make -j 256
then
    echo "Building failed"
    exit 1
fi
