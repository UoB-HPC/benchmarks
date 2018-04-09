#!/bin/bash

#PBS -N um-bdw
#PBS -o bdw.out
#PBS -e bdw.err
#PBS -q large
#PBS -l walltime=01:00:00
#PBS -l nodes=1

if [ -z "$PBS_O_WORKDIR" ]
then
    echo "Submit this script via qsub."
    exit 1
fi

cd $PBS_O_WORKDIR/bdw-swan

rm -rf run
mkdir run
cd run
cp -r $PBS_O_WORKDIR/amip/amip/data/* .
cp -r $PBS_O_WORKDIR/amip/common/data/* .
cp $PBS_O_WORKDIR/amip/common/scripts/wrapper .

echo "JOB SCRIPT STARTING"

export UMDIR="$UMDIR"
export CUMFDIR="$CYLC_TASK_WORK_PATH"
export DATAW="./"
export DATAM="./"
export INPUT_DATA="./"
export FLUME_IOS_NPROC="0"
export UM_ATM_NPROCX="4"
export UM_ATM_NPROCY="11"
export TOTAL_MPI_TASKS="$((UM_ATM_NPROCX*UM_ATM_NPROCY + FLUME_IOS_NPROC))"
export OMP_NUM_THREADS="2"
export OMP_STACKSIZE="2g"
export STASHMASTER="./"
export CORES_PER_NODE="44"
export NUMA_REGIONS_PER_NODE="2"
export HYPERTHREADS="2"
export MPI_TASKS_PER_NODE="$((CORES_PER_NODE*HYPERTHREADS/OMP_NUM_THREADS))"
export ROSE_LAUNCHER_PREOPTS="-ss -n $TOTAL_MPI_TASKS -N $MPI_TASKS_PER_NODE -S $((MPI_TASKS_PER_NODE/NUMA_REGIONS_PER_NODE)) -d $OMP_NUM_THREADS -j $HYPERTHREADS"
export MPICH_COLL_SYNC="MPI_Gatherv"
export FASTRUN=false

module swap cce cce/8.5.8
module swap cray-mpich/7.7.0 cray-mpich/7.5.5
module swap cray-libsci cray-libsci/16.11.1
module list 2>&1

export ATMOS_KEEP_MPP_STDOUT=true
export COUPLER=
export DR_HOOK=0
export DR_HOOK_CATCH_SIGNALS=0
export DR_HOOK_IGNORE_SIGNALS=0
export DR_HOOK_OPT=wallprof,self,time
export DR_HOOK_PROFILE=./drhook.prof.cray.%d
export DR_HOOK_PROFILE_LIMIT=-10.0
export DR_HOOK_PROFILE_PROC=-1
export ENS_MEMBER=0
export HISTORY=./atmos.xhist
export PRINT_STATUS=PrStatus_Min
export RCF_PRINTSTATUS=PrStatus_Normal
export RCF_TIMER=false
export RECON_KEEP_MPP_STDOUT=true
export RUNID=atmos
export SPECTRAL_FILE_DIR=./spectral

export PATH=$PBS_O_WORKDIR/amip/bin/:$PATH

export ATMOS_LAUNCHER="aprun $ROSE_LAUNCHER_PREOPTS"
./wrapper $PBS_O_WORKDIR/bdw-swan/build/build-atmos/bin/um-atmos.exe
