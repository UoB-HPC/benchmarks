#!/bin/bash

#PBS -N cp2k-bdw
#PBS -o bdw.out
#PBS -q large
#PBS -l nodes=1
#PBS -l walltime=00:15:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

DIR="$PWD/cp2k-5.1"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/exe/swan-bdw/cp2k.psmp" ]
then
    echo "Directory '$DIR' does not exist or does not contain exe/swan-bdw/cp2k.psmp"
    exit 1
fi

module swap craype-{broadwell,x86-skylake}
module swap PrgEnv-{cray,gnu}

rm -rf bdw
mkdir -p bdw
cd bdw
export OMP_NUM_THREADS=1
aprun -n 44 -d 1 -j 1 $DIR/exe/swan-bdw/cp2k.psmp -i $DIR/tests/QS/benchmark/H2O-64.inp
