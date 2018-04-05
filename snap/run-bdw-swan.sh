#!/bin/bash

#PBS -N snap-bdw
#PBS -o bdw.out
#PBS -q large
#PBS -l nodes=1
#PBS -l walltime=00:15:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

DIR="$PWD/SNAP"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/src/isnap-bdw" ]
then
    echo "Directory '$DIR' does not exist or does not contain isnap-bdw"
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
    >bdw.in

module swap craype-{broadwell,x86-skylake}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

export OMP_NUM_THREADS=1
aprun -n 44 -d 1 -j 1 ./isnap-bdw bdw.in bdw.out
cat bdw.out
