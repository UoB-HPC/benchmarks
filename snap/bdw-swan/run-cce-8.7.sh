#!/bin/bash

#PBS -N snap-bdw
#PBS -o cce-8.7.out
#PBS -q large
#PBS -l nodes=1
#PBS -l walltime=00:15:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

module swap cce cce/8.7.1

TARGET=csnap
CONFIG=cce-8.7
EXE=$TARGET-bdw-$CONFIG

cd $PBS_O_WORKDIR

DIR="$PWD/../SNAP"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/src/$EXE" ]
then
    echo "Directory '$DIR' does not exist or does not contain $EXE"
    exit 1
fi

cd $DIR/src

cat ../../benchmark.in \
    | sed 's/NY/22/' \
    | sed 's/NZ/8/' \
    | sed 's/NPEY/11/' \
    | sed 's/NPEZ/4/' \
    | sed 's/NTHREADS/1/' \
    | sed 's/ICHUNK/16/' \
    >$CONFIG.in

export OMP_NUM_THREADS=1
aprun -n 44 -d 1 -j 1 ./$EXE $CONFIG.in $CONFIG.out
cat $CONFIG.out
