#!/bin/bash

#PBS -N NAMD-knl
#PBS -o knl-intel-ht2.out
#PBS -q knl64
#PBS -l os=CLE_quad_flat
#PBS -l nodes=1
#PBS -l walltime=00:10:00
#PBS -joe

set -eu
set -o pipefail

if [ -z "${PBS_O_WORKDIR:-}" ]; then
    echo "Submit this script via qsub." >&2
    exit 1
fi

cd "$PBS_O_WORKDIR"

# Use the Intel Compiler
current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
module swap PrgEnv-$current_env PrgEnv-intel
module swap intel intel/18.0.0.128
module swap "craype-$CRAY_CPU_TARGET" craype-mic-knl
module load cray-fftw/3.3.6.3
module load craype-hugepages8M

numprocs=128

ts="$(date "+%Y-%m-%d_%H-%M-%S")"
runlog="stmv_knl_$ts.log"

aprun -d "$numprocs" -j 2 -cc depth numactl -m 1 ./NAMD-2.12-KNL-Intel-18-charm-6.8.2-cray-fftw-3.3.6.3/namd2 "+p$numprocs" stmv/stmv.namd +setcpuaffinity |& tee "$runlog"

days_ns=$(awk '/Benchmark/ {daysns=$8} END {print daysns}' "$runlog")
echo
echo "Benchmark metric: $days_ns days/ns"
echo "Full run log in: $runlog"

echo "Done."

