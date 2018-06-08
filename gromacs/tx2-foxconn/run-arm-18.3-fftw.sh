#!/bin/bash

DIR=arm-18.3-fftw

if [ ! -r "$DIR/build/bin/gmx" ]
then
    echo "$DIR/build/bin/gmx not found"
    exit 1
fi

module purge
module load arm/hpc-compiler/18.3

cd $DIR

export GMX_NBNXN_EWALD_TABLE=1
export GMX_MAXBACKUP=-1
$PWD/build/bin/gmx mdrun \
    -s ../../benchmarks/benchmarks/ion_channel_vsites.bench/pme-runs/topol.tpr \
    -noconfout -resethway -nsteps -1 -maxh 0.05 -v -quiet -nb cpu -ntmpi 32 -ntomp 8 -npme 0 -pin on -notunepme
