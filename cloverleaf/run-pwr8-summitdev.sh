#!/bin/bash


#BSUB -P CSC103SUMMITDEV
#BSUB -J cloverleaf-pwr8
#BSUB -nnodes 1
#BSUB -W 01:00
#BSUB -oo pwr8.out

if [ -z "$LS_SUBCWD" ]
then
    echo "Submit this script via bsub."
    exit 1
fi

cd $LS_SUBCWD

DIR="$PWD/CloverLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/clover_leaf_pwr8" ]
then
    echo "Directory '$DIR' does not exist or does not contain clover_leaf_pwr8"
    exit 1
fi

cd $DIR

module load gcc/7.1.1-20170802

cp InputDecks/clover_bm16.in clover.in

export OMP_NUM_THREADS=1
#jsrun -n 20 -a 1 -c 1 -b rs ./clover_leaf_pwr8
jsrun -n 20 -a 1 -c 1 ./clover_leaf_pwr8

