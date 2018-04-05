#!/bin/bash

#PBS -N neutral-knl
#PBS -o knl.out
#PBS -q knl64
#PBS -l nodes=1
#PBS -l os=CLE_quad_flat
#PBS -l walltime=00:30:00
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

if [ ! -r "$DIR/neutral.omp3.knl" ]
then
    echo "Directory '$DIR' does not exist or does not contain neutral.omp3.knl"
    exit 1
fi

cd $DIR

module swap craype-{broadwell,mic-knl}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

export OMP_PROC_BIND=true

# Try with no hyperthreads
export OMP_NUM_THREADS=64
aprun -n 1 -d 64 -j 1 -cc none numactl -m 1 ./neutral.omp3.knl problems/csp.params

# 2 threads/core
export OMP_NUM_THREADS=128
aprun -n 1 -d 128 -j 2 -cc none numactl -m 1 ./neutral.omp3.knl problems/csp.params

# 4 threads/core
export OMP_NUM_THREADS=256
aprun -n 1 -d 256 -j 4 -cc none numactl -m 1 ./neutral.omp3.knl problems/csp.params

