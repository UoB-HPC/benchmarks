#!/bin/bash

#PBS -N nemo-skl
#PBS -o skl20.out
#PBS -q batch
#PBS -l nodes=1
#PBS -l walltime=00:30:00
#PBS -l hostlist=\"[196-283]+[288-343]^\"
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

cd NEMO_benchmarks/NEMOGCM/CONFIG/SKL/EXP00

module load craype-x86-skylake
#module swap cce cce/8.7.0

export FORT_FMT_RECL=132
export OMP_NUM_THREADS=1
aprun -n 40 -d 1 -j 1 ./opa
grep "Average " timing.output
