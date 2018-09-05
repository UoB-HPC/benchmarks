#!/bin/bash

#PBS -N NAMD-skl
#PBS -q skl28
#PBS -l nodes=1
#PBS -l walltime=00:10:00
#PBS -joe

set -eu
set -o pipefail

cd "$PBS_O_WORKDIR"

exe="./NAMD-2.12-SKL-$COMPILER-charm-6.8.2-cray-fftw-3.3.6.3/namd2"
if [ ! -x "$exe" ]; then
    echo "Executable not found: $exe"
    echo "Have you run './benchmark build'?"
    exit 1
fi

numprocs=112

ts="$(date "+%Y-%m-%d_%H-%M")"
runlog="stmv_${BENCHMARK_PLATFORM}_${COMPILER}_$ts.log"

aprun -cc none "$exe" "+p$numprocs" stmv/stmv.namd +setcpuaffinity |& tee "$runlog"

days_ns=$(awk '/Benchmark/ {daysns=$8} END {print daysns}' "$runlog")
echo
echo "Benchmark metric: $days_ns days/ns"
echo "Full run log in: $runlog"

echo "Done."

