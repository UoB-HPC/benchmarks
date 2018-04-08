#!/bin/bash

#PBS -N NAMD-skl
#PBS -o skl.out
#PBS -q skl28
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

# Use the GNU Compiler
current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
module swap PrgEnv-$current_env PrgEnv-gnu

module load cray-fftw/3.3.6.3
module load craype-hugepages8M

numprocs=112

ts="$(date "+%Y-%m-%d_%H-%M")"
runlog="stmv_bdw_$ts.log"

aprun ./NAMD-2.12-SKL-GCC-7.3.0-charm-6.8.2-cray-fftw-3.3.6.3/namd2 "+p$numprocs" stmv/stmv.namd +setcpuaffinity |& tee "$runlog"

days_ns=$(awk '/Benchmark/ {daysns=$8} END {print daysns}' "$runlog")
echo
echo "Benchmark metric: $days_ns days/ns"
echo "Full run log in: $runlog"

echo "Done."

