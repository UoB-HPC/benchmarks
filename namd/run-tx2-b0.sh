#!/bin/bash

set -eu
set -o pipefail

# Use the Arm HPC Compiler
module purge
module load arm/hpc-compiler/18.1 cray-fftw/3.3.6.3

numprocs=256

pemap=''
if [ "$numprocs" -eq 64 ]; then
    pemap="+pemap 0-31,128-159"
elif [ "$numprocs" -eq 128 ]; then
    pemap="+pemap 0-63,128-191"
elif [ "$numprocs" -ne 256 ]; then
    echo "WARNING: +pemap not set automatically for $numprocs processes. Your results may be incorrect."
fi

ts="$(date "+%Y-%m-%d_%H-%M")"
runlog="tx2_stmv_$ts.log"

eval ./NAMD-2.12-TX2-armclang-18.1-charm-6.8.2-cray-fftw-3.3.6.3/namd2 "+p$numprocs" stmv/stmv.namd "$pemap" +setcpuaffinity |& tee "$runlog"

days_ns=$(awk '/Benchmark/ {daysns=$8} END {print daysns}' "$runlog")
echo
echo "Benchmark metric: $days_ns days/ns"
echo "Full run log in: $runlog"

echo "Done."

