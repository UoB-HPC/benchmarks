#!/bin/bash

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
#COMPILER=${2:-$DEFAULT_COMPILER}
MODEL=${2:-$DEFAULT_MODEL}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

case "$MODEL" in
  omp-target)
    module unload cudatoolkit/8.0.44
    module load cudatoolkit/9.1.85
    module use /lustre/projects/bristol/modules/modulefiles
    module load llvm/trunk
    MAKE_OPTS='\
      CC=clang \
      CFLAGS="-DDIFFUSE_OVERLOAD -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_60" \
      KERNELS="omp4_clang" \
      OPTIONS="-DNO_MPI"'
    export COMPILER=clang
    export SRC_DIR="$PWD/TeaLeaf/2d"
    export BENCHMARK_EXE="tealeaf.omp4_clang"
    ;;
  cuda)
    module load cudatoolkit/9.1.85
    export COMPILER=NVCC
    export SRC_DIR="$PWD/TeaLeaf_CUDA/"
    export BENCHMARK_EXE="tea_leaf"
    MAKE_OPTS='\
      COMPILER=GNU \
      CUDA_HOME="/global/opt/nvidia/cudatoolkit/9.1.85/" \
      NV_ARCH="PASCAL"'
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'"
    usage
    exit 1
    ;;

    # Set up the environment
esac


export CONFIG="p100"_"$COMPILER"_"$MODEL"
export RUN_DIR=$PWD/TeaLeaf-$CONFIG

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

  if [[ "$MODEL" = kokkos || $MODEL = "omp-target" ]]; then
    cp $SRC_DIR/tea.problems $RUN_DIR
    echo "4000 4000 10 9.5462351582214282e+01" >> "$RUN_DIR/tea.problems"
  fi

  qsub \
    -o TeaLeaf-$CONFIG.out \
    -N tealeaf \
    -V \
    $SCRIPT_DIR/run.job 
else
  echo
  echo "Invalid action (use 'build' or 'run')."
  echo
  exit 1
fi
