#!/bin/bash

#PBS -N OpenFOAM-knl
#PBS -o knl-ht4.out
#PBS -q knl64
#PBS -l nodes=1
#PBS -l os=CLE_quad_cache
#PBS -l walltime=01:00:00
#PBS -joe

set -eu
set -o pipefail

if [ -z "${PBS_O_WORKDIR:-}" ]; then
    echo "Submit this script via qsub." >&2
    exit 1
fi

cd "$PBS_O_WORKDIR"

if [ -n "${FOAM_INST_DIR:-}" ]; then
    echo "Using given OpenFOAM installation: $FOAM_INST_DIR"
else
    basedir="$PWD/OpenFOAM-v1712-KNL-Intel-18-cray-mpich-7.7.0"
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

    # Use the Intel compiler environment
    current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
    module swap PrgEnv-$current_env PrgEnv-intel
    module swap intel intel/18.0.0.128

    set +e +u 
    source "$bashrc" 
    set -eu
fi

testdir="run/block_DrivAer_small-knl-4ht"
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
    aprun decomposePar |& tee "decomposePar_$ts.log"
fi

export OMP_NUM_THREADS=1

aprun -n "$numprocs" -d 1 -j 4 simpleFoam -parallel |& tee "$runlog"

time_first=$(grep ExecutionTime "$runlog" | head -1 | awk '{print $3}')
time_last=$(grep ExecutionTime "$runlog" | tail -1 | awk '{print $3}')
time_diff=$(echo "$time_last - $time_first" | bc -l)
echo
echo "Benchmark time (total time - first step): $time_diff"

echo "Full run log: $runlog"
echo "Done."

