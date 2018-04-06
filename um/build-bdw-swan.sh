#!/bin/bash

#PBS -N um-bdw-build
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

export PATH=$PWD/fcm/bin:$PATH

cd bdw-swan
if ! aprun -n 1 -d 88 -j 2 ./build.sh
then
    echo "Building failed"
    exit 1
fi
