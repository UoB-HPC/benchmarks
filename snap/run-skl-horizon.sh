#!/bin/bash

#PBS -N snap-skl
#PBS -o skl20.out
#PBS -q batch
#PBS -l nodes=1
#PBS -l hostlist=\"[196-283]+[288-343]^\"
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

if [ ! -r "$DIR/src/isnap-skl" ]
then
    echo "Directory '$DIR' does not exist or does not contain isnap-skl"
    exit 1
fi

cd $DIR/src

cat ../../benchmark.in \
    | sed 's/NY/16/' \
    | sed 's/NZ/10/' \
    | sed 's/NPEY/8/' \
    | sed 's/NPEZ/5/' \
    | sed 's/NTHREADS/1/' \
    | sed 's/ICHUNK/16/' \
    >skl20.in

module load craype-x86-skylake
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

export OMP_NUM_THREADS=1
aprun -n 40 -d 1 -j 1 ./isnap-skl skl20.in skl20.out
cat skl20.out
