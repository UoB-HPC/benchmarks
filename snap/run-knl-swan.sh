#!/bin/bash

#PBS -N snap-knl
#PBS -o knl.out
#PBS -q knl64
#PBS -l nodes=1
#PBS -l os=CLE_quad_flat
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

if [ ! -r "$DIR/src/isnap-knl" ]
then
    echo "Directory '$DIR' does not exist or does not contain isnap-knl"
    exit 1
fi

cd $DIR/src

cat ../../benchmark.in \
    | sed 's/NY/16/' \
    | sed 's/NZ/16/' \
    | sed 's/NPEY/8/' \
    | sed 's/NPEZ/8/' \
    | sed 's/NTHREADS/1/' \
    | sed 's/ICHUNK/16/' \
    >knl.in

module swap craype-{broadwell,mic-knl}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

export OMP_NUM_THREADS=1
aprun -n 64 -d 1 -j 1 numactl -m 1 ./isnap-knl knl.in knl.out
cat knl.out
