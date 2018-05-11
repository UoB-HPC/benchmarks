#!/bin/bash

#PBS -N skl-build
#PBS -o skl-build20.out
#PBS -q batch
#PBS -l nodes=1
#PBS -l hostlist=\"[196-283]+[288-343]^\"
#PBS -l walltime=02:00:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

export PATH=$PWD/fcm/bin:$PATH

module load craype-x86-skylake

cd skl-swan
if ! aprun -n 1 -d 80 -j 2 ./build.sh
then
    echo "Building failed"
    exit 1
fi
