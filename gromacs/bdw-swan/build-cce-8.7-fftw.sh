#!/bin/bash

#PBS -N gromacs-bdw
#PBS -o cce-8.7-fftw-build.out
#PBS -q large
#PBS -l nodes=1
#PBS -l walltime=00:30:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR


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


module swap cce cce/8.7.1
module load fftw

CONFIG=cce-8.7-fftw


BUILD=$PWD/$CONFIG/build
rm -rf $BUILD
mkdir -p $BUILD
cd $BUILD
if ! aprun -n 1 -d 88 -j 2 cmake $DIR -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC \
    -DGMX_CYCLE_SUBCOUNTERS=ON \
    -DGMX_MPI=OFF -DGMX_GPU=OFF
then
    echo "Running cmake failed"
    exit 1
fi

# TODO: Proper fix for this (CMake generates "-l -lm" in link flags)
find . -name link.txt -exec sed -i 's/-l  -lm/-lm/g' {} \;
find . -name link.txt -exec sed -i 's/-l  -lrt/-lrt/g' {} \;

if ! aprun -n 1 -d 88 -j 2 make -j 88
then
    echo "Building failed"
    exit 1
fi
