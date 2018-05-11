#!/bin/bash

#PBS -N gromacs-skl
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

if [ ! -r "skl/build/bin/gmx" ]
then
    echo "skl/build/bin/gmx not found"
    exit 1
fi

module load craype-x86-skylake
module swap PrgEnv-{cray,gnu}
module load fftw

cd skl

export GMX_MAXBACKUP=-1
aprun -n 1 -d 80 -j 2 -cc none $PWD/build/bin/gmx mdrun \
    -s ../benchmarks/benchmarks/ion_channel_vsites.bench/pme-runs/topol.tpr \
    -noconfout -resethway -nsteps -1 -maxh 0.05 -v -quiet -nb cpu -ntmpi 40 -ntomp 2 -npme 0 -pin on -notunepme
