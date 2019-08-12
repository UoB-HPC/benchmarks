#!/bin/bash

DEFAULT_MODEL=intel-19.0
DEFAULT_MODEL=omp
function usage
{
  echo
  echo "Usage: ./benchmark.sh build|run [COMPILER] [MODEL]"
  echo 
  echo "Valid compilers:"
  echo "  gcc-8.1"
  echo "  gcc-9.1"
  echo "  intel-19.0"
  echo
  echo "Valid models:"
  echo "  omp"
  echo "  kokkos"
  echo
  echo "The default configuration is '$DEFAULT_COMPILER'."
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

export SRC_DIR="$PWD/minifmm/"

case "$COMPILER" in
  intel-19.0)
    module load intel/2019u4
    MAKE_OPTS="$MAKE_OPTS COMPILER=INTEL ARCH=host"
    ;;
  gcc-8.1)
    module load gcc/8.1.0
    MAKE_OPTS="$MAKE_OPTS COMPILER=GNU ARCH=native"
    ;;
  gcc-9.1)
    module load gcc/9.1.0
    MAKE_OPTS="$MAKE_OPTS COMPILER=GNU ARCH=native"
    ;;
  *)
    ;;
esac

case "$MODEL" in
  omp)
    export BENCHMARK_EXE="fmm.omp"
    MAKE_OPTS="$MAKE_OPTS MODEL=omp"
    ;;
  kokkos)
    case "$COMPILER" in 
        gcc-8.1)
            module load kokkos/2.8.00/gcc81
            ;;
        gcc-9.1)
            module load kokkos/2.8.00/gcc91
            ;;
        intel-19.0)
            module load kokkos/2.8.00/intel194
            ;;
        *)
            echo
            echo "Must use gcc-8.1 or gcc-9.1 with Kokkos"
            echo
            exit
            ;;
    esac
    export BENCHMARK_EXE="fmm.kokkos"
    MAKE_OPTS="$MAKE_OPTS MODEL=kokkos KOKKOS_TARGET=CPU"
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'"
    usage
    exit 1
    ;;

    # Set up the environment
esac


export CONFIG="naples"_"$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/minifmm-$CONFIG

# Handle actions
if [ "$ACTION" == "build" ]
then
  # Fetch source code
  if ! "$SCRIPT_DIR/../fetch.sh" $MODEL
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

  export RUN_ARGS="-i $SRC_DIR/inputs/large.in"

  #bash $SCRIPT_DIR/run.job &> minifmm-$CONFIG.out
  sbatch --output $RUN_DIR/minifmm-$CONFIG.out  $SCRIPT_DIR/run.job
else
  echo
  echo "Invalid action (use 'build' or 'run')."
  echo
  exit 1
fi
