#!/bin/bash

#PBS -N opensbli-bdw
#PBS -o cce-8.7.out
#PBS -e cce-8.7.err
#PBS -q large
#PBS -l nodes=1
#PBS -l walltime=00:20:00

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR


module swap cce cce/8.7.1
module load cray-hdf5-parallel

EXE=OpenSBLI_mpi_bdw_cce-8.7


DIR="$PWD/../OpenSBLI/Benchmark"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/$EXE" ]
then
    echo "Directory '$DIR' does not exist or does not contain $EXE"
    exit 1
fi

cd $DIR
export OMP_NUM_THREADS=1
aprun -n 44 -d 1 -j 1 ./$EXE
