#!/bin/bash

DEFAULT_COMPILER=intel-2018
DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
    echo "  gcc-7.3"
    echo "  intel-2018"
    echo "  pgi-18.10"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  kokkos"
    echo "  acc"
    echo "  ocl"
    echo
    echo "The default configuration is '$DEFAULT_COMPILER'."
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
COMPILER=${2:-$DEFAULT_COMPILER}
MODEL=${3:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export CONFIG="skl"_"$COMPILER"_"$MODEL"
export BENCHMARK_EXE=stream-$CONFIG
export SRC_DIR=$SCRIPT_DIR/BabelStream/
export RUN_DIR=$SCRIPT_DIR


# Set up the environment
module swap craype-{broadwell,x86-skylake}
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        MAKE_OPTS='COMPILER=CRAY'
        ;;
    gcc-7.3)
        module swap PrgEnv-{cray,gnu}
        module swap gcc gcc/7.3.0
        MAKE_OPTS='COMPILER=GNU EXTRA_FLAGS="-march=skylake-avx512"'
        ;;
    intel-2018)
        module swap PrgEnv-{cray,intel}
        module swap intel intel/18.0.0.128
        MAKE_OPTS='COMPILER=INTEL EXTRA_FLAGS=-xCORE-AVX512'
        ;;
    pgi-18.10)
        module swap PrgEnv-{cray,pgi}
        module swap pgi pgi/18.10.0
	MAKE_OPTS='COMPILER=PGI EXTRA_FLAGS="-ta=multicore -tp=skylake"'
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
        ;;
esac

# Select Makefile to use, and model specific information
case "$MODEL" in
  omp)
    MAKE_FILE="OpenMP.make"
    BINARY="omp-stream"
    MAKE_OPTS+=" TARGET=CPU"
    ;;
  kokkos)
    module use /lus/scratch/p02555/modules/modulefiles
    module load kokkos/skylake
    MAKE_FILE="Kokkos.make"
    BINARY="kokkos-stream"
    if [ "$COMPILER" != "intel-2018" ]
    then
      echo
      echo " Must use Intel with Kokkos module"
      echo
      exit 1
    fi
    ;;
  acc)
    MAKE_FILE="OpenACC.make"
    BINARY="acc-stream"
    MAKE_OPTS+=' TARGET=SKL'
    if [ "$COMPILER" != "pgi-18.10" ]
    then
      echo
      echo " Must use PGI with OpenACC"
      echo
      exit 1
    fi
  ;;
  ocl)
    module use /lus/scratch/p02555/modules/modulefiles
    module load opencl/intel
    MAKE_FILE="OpenCL.make"
    BINARY="ocl-stream"
    export LD_PRELOAD=/lus/scratch/p02555/modules/intel-opencl/lib/libintelocl.so
    #export LD_PRELOAD=/lus/scratch/p02100/l_opencl_p_18.1.0.013/opt/intel/opencl_compilers_and_libraries_18.1.0.013/linux/compiler/lib/intel64_lin/libintelocl.so
  ;;
esac


# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! "$SCRIPT_DIR/../fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi


    # Perform build
    if ! eval make -f $MAKE_FILE -C $SRC_DIR -B $MAKE_OPTS
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

    mkdir -p $RUN_DIR
    # Rename binary
    mv $SRC_DIR/$BINARY $RUN_DIR/$BENCHMARK_EXE

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
        -o BabelStream-$CONFIG.out \
        -N babelstream \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
