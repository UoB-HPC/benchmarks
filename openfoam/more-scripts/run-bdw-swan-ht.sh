#!/bin/bash

#PBS -N OpenFOAM-bdw
#PBS -o bdw-ht.out
#PBS -q large
#PBS -l nodes=1
#PBS -l walltime=00:15:00
#PBS -joe

set -eu
set -o pipefail

if [ -z "${PBS_O_WORKDIR:-}" ]; then
    echo "Submit this script via qsub."
    exit 1
fi

cd "$PBS_O_WORKDIR"

if [ -n "${FOAM_INST_DIR:-}" ]; then
    echo "$0: Using given OpenFOAM installation: $FOAM_INST_DIR" >&2
else
    basedir="$PWD/OpenFOAM-v1712-GCC-7.3.0-cray-mpich-7.7.0"
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

    # Use the GNU Compiler
    current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
    module swap PrgEnv-$current_env PrgEnv-gnu

    set +e +u 
    source "$bashrc" 
    set -eu
fi

testdir="run/block_DrivAer_small-bdw-ht"
numprocs=88

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

procdirs=$(set +o pipefail && ls -d processor* 2>/dev/null | wc -l)
if [ "$procdirs" -ne "$numprocs" ]; then
    decomposePar |& tee "decomposePar_$ts.log"
fi

aprun -n "$numprocs" -d 1 -j 2 simpleFoam -parallel |& tee "$runlog"

time_first=$(grep ExecutionTime "$runlog" | head -1 | awk '{print $3}')
time_last=$(grep ExecutionTime "$runlog" | tail -1 | awk '{print $3}')
time_diff=$(echo "$time_last - $time_first" | bc -l)
echo "$0: Benchmark time (total time - first step): $time_diff" >&2

echo "$0: Full run log: $runlog" >&2
echo "$0: Done." >&2

