#!/bin/bash

#PBS -N cloverleaf-bdw
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

DIR="$PWD/CloverLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/clover_leaf_bdw" ]
then
    echo "Directory '$DIR' does not exist or does not contain clover_leaf_bdw"
    exit 1
fi

cd $DIR

module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

cp InputDecks/clover_bm16.in clover.in

OMP_NUM_THREADS=1 aprun -n 44 -d 1 -j 1 ./clover_leaf_bdw
