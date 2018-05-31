#!/bin/bash

set -eu
set -o pipefail

if [ -n "${FOAM_INST_DIR:-}" ]; then
    echo "Using given OpenFOAM installation: $FOAM_INST_DIR"
else
    basedir="$PWD/OpenFOAM-v1712-TX2-armclang-18.3-OpenMPI-3.0.0"
    [ $# -gt 0 ] && basedir="$1"

    if [ ! -d "$basedir" ]; then
        echo "$0: OpenFOAM installation direcotry does not exist: $basedir" >&2
        echo "$0: Stop." >&2
        exit 1
    fi

    bashrc="$basedir/OpenFOAM-v1712/etc/bashrc"

    if [ ! -f "$bashrc" ]; then
        echo "$0: File does not exist: $PWD/$bashrc" >&2
        echo "$0: Stop." >&2
        exit 2
    fi

    module purge
    module load arm/hpc-compiler/18.3 openmpi/3.0.0/arm-18.3

    set +e +u
    source "$bashrc"
    set -eu
fi

testdir="run/block_DrivAer_small-tx2-ht4"
numprocs=256

if [ ! -d "$testdir" ]; then
    echo "$0: Run directory does not exist: $PWD/$testdir" >&2
    echo "$0: Have you copied over your test case?" >&2
    echo "$0: Stop." >&2
    exit 3
fi

cd "$testdir"

# Set the number of processors
sed -i 's/^numberOfSubdomains.*/numberOfSubdomains '"$numprocs"';/' system/decomposeParDict

ts="$(date "+%Y-%m-%d_%H-%M")"
runlog="simpleFoam_$ts.log"

procdirs=$(find -maxdepth 1 -type d -name 'processor*' -printf '.' | wc -c)
if [ "$procdirs" -ne "$numprocs" ]; then
    decomposePar |& tee "decomposePar_$ts.log"
fi

export OMP_NUM_THREADS=1

mpirun --mca btl vader,self --map-by ppr:4:core --use-hwthread-cpus --report-bindings -np "$numprocs" simpleFoam -parallel |& tee "$runlog"

time_first=$(grep ExecutionTime "$runlog" | head -1 | awk '{print $3}')
time_last=$(grep ExecutionTime "$runlog" | tail -1 | awk '{print $3}')
time_diff=$(echo "$time_last - $time_first" | bc -l)
echo
echo "Benchmark time (total time - first step): $time_diff"

echo "Full run log: $runlog"
echo "Done."

