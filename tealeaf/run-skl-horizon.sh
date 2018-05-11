#!/bin/bash

#PBS -N tealeaf-skl
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

DIR="$PWD/TeaLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/tea_leaf_skl" ]
then
    echo "Directory '$DIR' does not exist or does not contain tea_leaf_skl"
    exit 1
fi

cd $DIR

module load craype-x86-skylake
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

cp Benchmarks/tea_bm_5.in tea.in

OMP_NUM_THREADS=1 aprun -n 40 -d 1 -j 1 ./tea_leaf_skl
