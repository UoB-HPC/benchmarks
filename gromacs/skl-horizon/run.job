#!/bin/bash
#PBS -q batch
#PBS -l nodes=1
#PBS -l hostlist=\"[196-283]+[288-343]^\"
#PBS -l walltime=00:15:00
#PBS -joe

export GMX_MAXBACKUP=-1
aprun -n 1 -d 80 -j 2 -cc none $BUILD_DIR/bin/gmx mdrun \
    -s $BENCHMARK_DIR/benchmarks/ion_channel_vsites.bench/pme-runs/topol.tpr \
    -noconfout -resethway -nsteps -1 -maxh 0.05 -quiet \
    -nb cpu -ntmpi 40 -ntomp 2 -npme 0 -pin on -notunepme
