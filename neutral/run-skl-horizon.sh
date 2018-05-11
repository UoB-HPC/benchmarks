#!/bin/bash

#PBS -N neutral-skl
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

module load craype-x86-skylake
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

export OMP_PROC_BIND=true
export OMP_NUM_THREADS=80
aprun -n 1 -d 80 -j 2 -cc none ./neutral.omp3.skl problems/csp.params
