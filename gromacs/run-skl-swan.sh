#!/bin/bash

#PBS -N gromacs-skl
#PBS -o skl.out
#PBS -q skl28
#PBS -l nodes=1
#PBS -l walltime=00:15:00
#PBS -joe

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR

if [ ! -r "skl/build/bin/gmx" ]
then
    echo "skl/build/bin/gmx not found"
    exit 1
fi

module swap craype-{broadwell,x86-skylake}
module swap PrgEnv-{cray,gnu}
module load fftw

cd skl

export GMX_MAXBACKUP=-1
aprun -n 1 -d 112 -j 2 -cc none $PWD/build/bin/gmx mdrun \
    -s ../benchmarks/benchmarks/ion_channel_vsites.bench/pme-runs/topol.tpr \
    -noconfout -resethway -nsteps -1 -maxh 0.05 -v -quiet -nb cpu -ntmpi 56 -ntomp 2 -npme 0 -pin on -notunepme
