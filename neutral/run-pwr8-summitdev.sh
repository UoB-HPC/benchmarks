#!/bin/bash

#BSUB -P CSC103SUMMITDEV
#BSUB -J neutral-pwr8
#BSUB -nnodes 1
#BSUB -W 01:00
#BSUB -oo pwr8.out

if [ -z "$LS_SUBCWD" ]
then
    echo "Submit this script via bsub."
    exit 1
fi

cd $LS_SUBCWD

DIR="$PWD/arch/neutral"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/neutral.omp3.pwr8" ]
then
    echo "Directory '$DIR' does not exist or does not contain neutral.omp3.pwr8"
    exit 1
fi

cd $DIR

module load gcc/7.1.1-20170802

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=20
jsrun -n 1 -a 1 -c 20 -b rs ./neutral.omp3.pwr8 problems/csp.params

