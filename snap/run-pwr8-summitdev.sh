#!/bin/bash

#BSUB -P CSC103SUMMITDEV
#BSUB -J snap-pwr8
#BSUB -nnodes 1
#BSUB -W 01:00
#BSUB -oo pwr8.out

if [ -z "$LS_SUBCWD" ]
then
    echo "Submit this script via bsub."
    exit 1
fi

cd $LS_SUBCWD

DIR="$PWD/SNAP"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/src/gsnap-pwr8" ]
then
    echo "Directory '$DIR' does not exist or does not contain gsnap-pwr8"
    exit 1
fi

cd $DIR/src

cat ../../benchmark.in \
    | sed 's/NY/10/' \
    | sed 's/NZ/8/' \
    | sed 's/NPEY/5/' \
    | sed 's/NPEZ/4/' \
    | sed 's/NTHREADS/1/' \
    | sed 's/ICHUNK/16/' \
    >pwr8.in

module load gcc/7.1.1-20170802

export OMP_NUM_THREADS=1
jsrun -n 20 -a 1 -c 1 ./gsnap-pwr8 pwr8.in pwr8.out
cat pwr8.out
