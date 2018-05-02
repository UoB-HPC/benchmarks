#!/bin/bash


#BSUB -P CSC103SUMMITDEV
#BSUB -J tealeaf-pwr8
#BSUB -nnodes 1
#BSUB -W 01:00
#BSUB -oo pwr8.out

if [ -z "$LS_SUBCWD" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $LS_SUBCWD

DIR="$PWD/TeaLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/tea_leaf_pwr8" ]
then
    echo "Directory '$DIR' does not exist or does not contain tea_leaf_pwr8"
    exit 1
fi

cd $DIR

module load gcc/7.1.1-20170802

cp Benchmarks/tea_bm_5.in tea.in

export OMP_NUM_THREADS=1
jsrun -n 20 -a 1 -c 1 ./tea_leaf_pwr8

