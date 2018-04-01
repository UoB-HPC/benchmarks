#!/bin/bash

#PBS -N gromacs-bdw
#PBS -o bdw-build.out
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


DIR="$PWD/gromacs-2018.1"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/CMakeLists.txt" ]
then
    echo "Directory '$DIR' does not exist or does not contain CMakeLists.txt"
    exit 1
fi


module swap PrgEnv-{cray,gnu}
module load fftw

BUILD=$PWD/bdw/build
rm -rf $BUILD
mkdir -p $BUILD
cd $BUILD
if ! aprun -n 1 -d 88 -j 2 cmake $DIR -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
    -DGMX_MPI=OFF -DGMX_GPU=OFF
then
    echo "Running cmake failed"
    exit 1
fi

if ! aprun -n 1 -d 88 -j 2 make -j 88
then
    echo "Building failed"
    exit 1
fi
