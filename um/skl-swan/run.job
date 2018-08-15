#!/bin/bash
#PBS -q skl28
#PBS -l nodes=1
#PBS -l walltime=00:30:00
#PBS -joe

rm -rf run
mkdir run
cd run
cp -r $SRC_DIR/amip/data/* .
cp -r $SRC_DIR/common/data/* .
cp $SRC_DIR/common/scripts/wrapper .

echo "JOB SCRIPT STARTING"

export UMDIR="$UMDIR"
export CUMFDIR="$CYLC_TASK_WORK_PATH"
export DATAW="./"
export DATAM="./"
export INPUT_DATA="./"
export FLUME_IOS_NPROC="0"
export UM_ATM_NPROCX="8"
export UM_ATM_NPROCY="7"
export TOTAL_MPI_TASKS="$((UM_ATM_NPROCX*UM_ATM_NPROCY + FLUME_IOS_NPROC))"
export OMP_NUM_THREADS="2"
export OMP_STACKSIZE="2g"
export STASHMASTER="./"
export CORES_PER_NODE="56"
export NUMA_REGIONS_PER_NODE="2"
export HYPERTHREADS="2"
export MPI_TASKS_PER_NODE="$((CORES_PER_NODE*HYPERTHREADS/OMP_NUM_THREADS))"
export ROSE_LAUNCHER_PREOPTS="-ss -n $TOTAL_MPI_TASKS -N $MPI_TASKS_PER_NODE -S $((MPI_TASKS_PER_NODE/NUMA_REGIONS_PER_NODE)) -d $OMP_NUM_THREADS -j $HYPERTHREADS"
export MPICH_COLL_SYNC="MPI_Gatherv"
export FASTRUN=false

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

export PATH=$SRC_DIR/bin/:$PATH
export LD_LIBRARY_PATH=$BUILD_DIR/shumlib/lib/:$LD_LIBRARY_PATH

export ATMOS_LAUNCHER="aprun $ROSE_LAUNCHER_PREOPTS"
./wrapper $BUILD_DIR/build-atmos/bin/um-atmos.exe
