#!/bin/bash

#PBS -N um-skl-build
#PBS -o skl-build.out
#PBS -q skl28
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

cd skl-swan
if ! aprun -n 1 -d 112 -j 2 ./build.sh
then
    echo "Building failed"
    exit 1
fi
