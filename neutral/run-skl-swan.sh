#!/bin/bash

#PBS -N neutral-skl
#PBS -o skl.out
#PBS -q skl28
#PBS -l nodes=1
#PBS -l walltime=00:15:00
#PBS -joe

cd $PBS_O_WORKDIR

DIR="$PWD/arch/neutral"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/neutral.omp3.skl" ]
then
    echo "Directory '$DIR' does not exist or does not contain neutral.omp3.skl"
    exit 1
fi

cd $DIR

module swap craype-{broadwell,x86-skylake}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=112
aprun -n 1 -d 112 -j 2 -cc none ./neutral.omp3.skl problems/csp.params
