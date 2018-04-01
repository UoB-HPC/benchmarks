#!/bin/bash

#PBS -N gromacs-bdw
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

if [ ! -r "bdw/build/bin/gmx" ]
then
    echo "bdw/build/bin/gmx not found"
    exit 1
fi


module swap PrgEnv-{cray,gnu}
module load fftw

cd bdw

export GMX_MAXBACKUP=-1
aprun -n 1 -d 88 -j 2 -cc none $PWD/build/bin/gmx mdrun \
    -s ../benchmarks/benchmarks/ion_channel_vsites.bench/pme-runs/topol.tpr \
    -noconfout -resethway -nsteps -1 -maxh 0.05 -v -quiet -nb cpu -ntmpi 40 -ntomp 2 -npme 0 -pin on -notunepme
