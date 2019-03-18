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
    module load cudatoolkit/8.0.44
    module load craype-accel-nvidia60
    module load craype-broadwell
    MAKE_OPTS='\
      CC=cc \
      COMPILER=CRAY \
      OPTIONS=-DNO_MPI \
      KERNELS=omp4'
    export COMPILER=CRAY
    export BENCHMARK_EXE="tealeaf.omp4"
    export SRC_DIR="$PWD/TeaLeaf/2d"
    #module unload cudatoolkit/8.0.44
    #module use /lustre/projects/bristol/modules/modulefiles
    #module load llvm/trunk
    #MAKE_OPTS='\
    #  CC=clang \
    #  CFLAGS="-DDIFFUSE_OVERLOAD -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_60" \
    #  KERNELS="omp4_clang" \
    #  OPTIONS="-DNO_MPI"'
    #export COMPILER=clang
    #export SRC_DIR="$PWD/TeaLeaf/2d"
    #export BENCHMARK_EXE="tealeaf.omp4_clang"
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
  kokkos)
    module use /lustre/projects/bristol/modules/modulefiles
    module load kokkos/pascal
    KOKKOS_CXXFLAGS=$(grep KOKKOS_CXXFLAGS $KOKKOS_PATH/Makefile.kokkos | cut -d '=' -f 2- )
    export SRC_DIR="$PWD/TeaLeaf/2d"
    export BENCHMARK_EXE="tealeaf.kokkos"
    NVCC_WRAPPER="$KOKKOS_PATH/bin/nvcc_wrapper"
    KERNELS_PATH="$SRC_DIR/c_kernels/kokkos"
    export MAKEFLAGS="-j36"
    export COMPILER=NVCC
    MAKE_OPTS='\
      CC="$NVCC_WRAPPER" \
      CPP="$NVCC_WRAPPER"  \
      KERNEL_FLAGS="$KOKKOS_CXXFLAGS -DNO_MPI -DCUDA -I$KERNELS_PATH" \
      KERNELS=kokkos' \
    ;;
  acc)
    module load pgi/18.10
    export SRC_DIR="$PWD/TeaLeaf/2d"
    export BENCHMARK_EXE="tealeaf.openacc"
    export COMPILER=PGI
    MAKE_OPTS='\
      OACC_FLAGS="-ta=tesla,cc60 -tp=haswell-64" \
      COMPILER=PGI \
      CC=pgcc \
      OPTIONS=-DNO_MPI \
      KERNELS="openacc"'
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

  if [ "$MODEL" == "kokkos" ]; then
    sed -i 's/$(TL_LINK) $(TL_FLAGS) $(OBJS) $(KERNEL_OBJS) $(TL_LDFLAGS) -o tealeaf.$(KERNELS)/$(TL_LINK) $(OBJS) $(KERNEL_OBJS) $(TL_LDFLAGS) -o tealeaf.$(KERNELS)/' "$SRC_DIR/Makefile"
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

  if [[ "$MODEL" = kokkos || $MODEL = "omp-target" || $MODEL = "acc" ]]; then
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
