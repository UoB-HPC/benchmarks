#!/bin/bash

set -eu

DEFAULT_MODEL=cuda
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [MODEL]"
    echo
    echo "Valid models:"
    echo "  omp-target"
    echo "  cuda"
    echo "  kokkos"
    echo "  acc"
    echo
    echo "The default programming model is '$DEFAULT_MODEL'."
    echo
}

# Process arguments
if [ $# -lt 1 ]
then
    usage
    exit 1
fi

ACTION=$1
export MODEL=${2:-$DEFAULT_MODEL}
SCRIPT=`basename $0`
SCRIPT_DIR=`dirname $0`
export BENCHMARK_EXE=clover_leaf

module use /lustre/projects/bristol/modules-power/modulefiles
module purge
case "$MODEL" in
    omp-target)
        module load llvm/trunk
        module load gcc/8.1.0
        module load openmpi/3.0.2/gcc8
        export SRC_DIR="$PWD/CloverLeaf-OpenMP4"
        export OMPI_CC=clang OMPI_FC=gfortran
        MAKE_OPTS='-j20 COMPILER=GNU MPI_F90=mpif90 MPI_C=mpicc MPI_LD=mpicc'
        MAKE_OPTS="$MAKE_OPTS FLAGS_GNU='-O3 -mcpu=power9'"
        MAKE_OPTS="$MAKE_OPTS CFLAGS_GNU='-O3 -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_70' LDLIBS='-lrt -lm -lgfortran -lgomp -lmpi_mpifh'"
        MAKE_OPTS="$MAKE_OPTS LDFLAGS='-O3 -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_70'"
        ;;
    cuda)
        module load cuda/10.0
        module load mpi/openmpi-ppc64le
        export SRC_DIR="$PWD/CloverLeaf_CUDA"
        MAKE_OPTS="-j20 COMPILER=GNU NV_ARCH=VOLTA CODEGEN_VOLTA='-gencode arch=compute_70,code=sm_70'"
        ;;
    kokkos)
       module load kokkos/volta
       module load openmpi/3.0.2/gcc8
       export SRC_DIR="$PWD/cloverleaf_kokkos"
       MAKE_OPTS='-j -f Makefile.gpu'
       ;;
    acc)
       module load pgi/18.10
       export PATH=/opt/pgi/linuxpower/18.10/mpi/openmpi/bin/:$PATH
       export SRC_DIR="$PWD/CloverLeaf-OpenACC"
       MAKE_OPTS='COMPILER=PGI C_MPI_COMPILER=mpicc MPI_F90=mpif90 FLAGS_PGI="-O3 -Mpreprocess -fast -acc -ta=tesla:cc70" CFLAGS_PGI="-O3 -ta=tesla:cc70" OMP_PGI=""'
       ;;
    *)
        echo
        echo "Invalid model '$MODEL'."
        usage
        exit 1
        ;;
esac

export CONFIG="v100_$MODEL"
export RUN_DIR="$PWD/CloverLeaf-$CONFIG"

# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! eval "$SCRIPT_DIR/../fetch.sh $MODEL"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    # Perform build
    rm -f "$SRC_DIR/$BENCHMARK_EXE" "$RUN_DIR/$BENCHMARK_EXE"
    make -C "$SRC_DIR" clean
    if ! eval make -C "$SRC_DIR" -B "$MAKE_OPTS"
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

    mkdir -p $RUN_DIR
    mv $SRC_DIR/$BENCHMARK_EXE $RUN_DIR

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$RUN_DIR/$BENCHMARK_EXE" ]
    then
        echo "Executable '$RUN_DIR/$BENCHMARK_EXE' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    bash "$SCRIPT_DIR/run.sh"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
