#!/bin/bash

#PBS -N nemo-bdw
#PBS -o bdw.out
#PBS -q large
#PBS -l nodes=1
#PBS -l walltime=00:30:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

cd NEMO_benchmarks/NEMOGCM/CONFIG/BDW/EXP00

module swap cce cce/8.7.0

export FORT_FMT_RECL=132
export OMP_NUM_THREADS=1
aprun -n 44 -d 1 -j 1 ./opa
grep "Average " timing.output
