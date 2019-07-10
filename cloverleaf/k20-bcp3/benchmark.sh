#!/bin/bash

DEFAULT_MODEL=omp-target
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [MODEL [COMPILER]]"
    echo
    echo "Valid models:"
    echo "  omp-target"
    echo "  kokkos"
    echo "  cuda"
    echo "  opencl"
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
MODEL=${2:-$DEFAULT_MODEL}
SCRIPT=`basename $0`
SCRIPT_DIR=`dirname $0`
export BENCHMARK_EXE=clover_leaf

case "$MODEL" in
    omp-target)
        COMPILER=clang-9
        module use /newhome/pa13269/modules/modulefiles
        module load llvm
        module load openmpi3-gcc4.8
        module load languages/gcc-4.8.4
        module load cuda/toolkit/7.5.18

        export MAKEFLAGS='-j16'
        export SRC_DIR=$PWD/CloverLeaf-OpenMP4
        export OMPI_MPICC=clang
        export OMPI_FC=gfortran

        # TODO: get rid of the extraneous flags here
        # Flags for clang
        export CFLAGS="\
            -O3 -DOFFLOAD -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_35 \
            -I/newhome/pa13269/modules/install/llvm/include -L/newhome/pa13269/modules/install/llvm/lib \
            -lomptarget -lomp -lpthread -lgfortran -pthread -Wl,-rpath -Wl,/newhome/pa13269/modules/openmpi3-gcc4.8/lib \
            -Wl,--enable-new-dtags -L/newhome/pa13269/modules/openmpi3-gcc4.8/lib -lmpi -lmpi_mpifh"
        # Flags for gfortran
        export FLAGS="\
            -O3 -DOFFLOAD -L/newhome/pa13269/modules/openmpi3-gcc4.8/lib -L/cm/shared/languages/GCC-4.8.4/lib \
            -I/newhome/pa13269/modules/install/llvm/include -L/newhome/pa13269/modules/install/llvm/lib \
            -lomptarget -lomp -lpthread -lgfortran -pthread -I/newhome/pa13269/modules/openmpi3-gcc4.8/lib -Wl,-rpath \
            -Wl,/newhome/pa13269/modules/openmpi3-gcc4.8/lib -Wl,--enable-new-dtags \
            -L/newhome/pa13269/modules/openmpi3-gcc4.8/lib -lmpi_usempi -lmpi_mpifh -lmpi"

        MAKE_OPTS='\
          COMPILER=CLANG MPI_C=mpicc MPI_F90=mpif90 CFLAGS="${CFLAGS}" FLAGS="${FLAGS}"'
        ;;
    kokkos)
        COMPILER=${3:-gcc-7.1.0}
        case "$COMPILER" in
            gcc-7.1.0)
                COMPILER=gcc-7.1.0
                module use /newhome/pa13269/modules/modulefiles
                module load languages/gcc-7.1.0
                module load openmpi3-gcc4.8
            ;;
            intel-16)
                COMPILER=intel-16
                module load languages/intel-compiler-16-u2
            ;;
            *)
                echo
                echo "Invalid compiler '$COMPILER'."
                usage
                exit 1
            ;;
        esac

        module use /newhome/pa13269/modules/modulefiles
        module load kokkos
        module load cuda/toolkit/7.5.18
        export MAKE_OPTS="-j -f Makefile.gpu KOKKOS_PATH=$KOKKOS_PATH"
        export SRC_DIR="$PWD/cloverleaf_kokkos"
        ;;
    cuda)
        COMPILER=nvcc-7.5.18
        module load cuda/toolkit/7.5.18
        export MAKEFLAGS='-j16'
        export SRC_DIR=$PWD/CloverLeaf
        mkdir -p $SRC_DIR/obj $SRC_DIR/mpiobj
        MAKE_OPTS='COMPILER=CUDA USE_CUDA=1'
        ;;
    opencl)
        COMPILER=intel-16
        module load languages/intel-compiler-16-u2
        module load cuda/toolkit/7.5.18
        export SRC_DIR=$PWD/CloverLeaf
        mkdir -p $SRC_DIR/obj $SRC_DIR/mpiobj
        export OCL_SRC_PREFIX=$SRC_DIR
        MAKE_OPTS='COMPILER=INTEL USE_OPENCL=1 MPI_CC_INTEL=mpiicc \
            EXTRA_INC="-I/cm/shared/apps/cuda-7.5.18/include/CL" \
            EXTRA_PATH="-I/cm/shared/apps/cuda-7.5.18/include/CL"'
        ;;
    acc)
        COMPILER=${3:-pgi-18.4}
        case "$COMPILER" in
#            gcc-7.1.0)
#                module load languages/gcc-7.1.0
#                MAKE_OPTS='COMPILER=GNU OPTIONS="-cpp -fopenacc"'
#            ;;
#            intel-16)
#                module load languages/intel-compiler-16-u2
#                MAKE_OPTS='COMPILER=INTEL MPI_COMPILER=mpiifort \
#                    C_MPI_COMPILER=mpiicc OPTIONS="-cpp -fopenacc"'
#            ;;
            pgi-18.4)
                module load languages/pgi-18.4
                export OMPI_CC=pgcc
                export OMPI_FC=pgfortran
                export LD_LIBRARY_PATH=/cm/shared/languages/PGI-2018-184/linux86-64-llvm/18.4/lib:$LD_LIBRARY_PATH
                MAKE_OPTS="COMPILER=PGI C_MPI_COMPILER=mpicc MPI_F90=mpif90 \
                    FLAGS_PGI='-fast -acc -cpp -ta=tesla,cc35'
                    OPTIONS='-noswitcherror' C_OPTIONS='-noswitcherror'"
            ;;
            *)
                echo
                echo "Invalid compiler '$COMPILER'."
                usage
                exit 1
            ;;
        esac

        module load cuda/toolkit/7.5.18
        export SRC_DIR=$PWD/CloverLeaf-OpenACC
        mkdir -p $SRC_DIR/obj $SRC_DIR/mpiobj
        ;;
    *)
        echo
        echo "Invalid model '$MODEL'."
        usage
        exit 1
        ;;
esac

export CONFIG="$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/$CONFIG

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
    rm -f $SRC_DIR/$BENCHMARK_EXE $RUN_DIR/$BENCHMARK_EXE
    if ! eval make -C $SRC_DIR -B $MAKE_OPTS
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

    qsub $SCRIPT_DIR/run.job \
        -d $RUN_DIR \
        -o CloverLeaf-$CONFIG.out \
        -N cloverleaf \
        -n -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
