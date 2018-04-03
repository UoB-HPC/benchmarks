#!/bin/bash

#PBS -N tealeaf-knl
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

DIR="$PWD/TeaLeaf_ref"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/tea_leaf_knl" ]
then
    echo "Directory '$DIR' does not exist or does not contain tea_leaf_knl"
    exit 1
fi

cd $DIR

module swap craype-{broadwell,mic-knl}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

cp Benchmarks/tea_bm_5.in tea.in

OMP_NUM_THREADS=1 aprun -n 64 -d 1 -j 1 numactl -m 1 ./tea_leaf_knl
