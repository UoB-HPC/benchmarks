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
    module use /lustre/projects/bristol/modules-power/modulefiles
    module load llvm/trunk
    export MAKEFLAGS='-j36'
    MAKE_OPTS='\
      CC=clang \
      CFLAGS="-O3 -DDIFFUSE_OVERLOAD -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_70" \
      TL_LDFLAGS="-fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_70 -lm -lrt" \
      KERNELS="omp4_clang" \
      OPTIONS="-DNO_MPI"'
    export COMPILER=clang
    export SRC_DIR="$PWD/TeaLeaf/2d"
    export BENCHMARK_EXE="tealeaf.omp4_clang"
    ;;
  cuda)
    module use /lustre/projects/bristol/modules-power/modulefiles
    module load cuda/10.0
    module load mpi/openmpi-ppc64le
    export COMPILER=NVCC
    export SRC_DIR="$PWD/TeaLeaf_CUDA/"
    export BENCHMARK_EXE="tea_leaf"
    MAKE_OPTS='\
      COMPILER=GNU \
      CUDA_HOME="/usr/local/cuda-10.0/" \
      NV_ARCH="VOLTA"'
    ;;
  kokkos)
    module use /lustre/projects/bristol/modules-power/modulefiles
    module load kokkos/volta
    KOKKOS_CXXFLAGS=$(grep KOKKOS_CXXFLAGS $KOKKOS_PATH/Makefile.kokkos | cut -d '=' -f 2- )
    export SRC_DIR="$PWD/TeaLeaf/2d"
    export BENCHMARK_EXE="tealeaf.kokkos"
    NVCC_WRAPPER="$KOKKOS_PATH/bin/nvcc_wrapper"
    KERNELS_PATH="$SRC_DIR/c_kernels/kokkos"
    export MAKEFLAGS="-j40"
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
      OACC_FLAGS="-ta=tesla,cc70 -tp=pwr9" \
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


export CONFIG="v100"_"$COMPILER"_"$MODEL"
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

  #sed -i 's/-march=native/-mcpu=powerpc64le -mtune=powerpc64le/' "$SRC_DIR/Makefile"
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

  bash $SCRIPT_DIR/run.job &> TeaLeaf-$CONFIG.out
else
  echo
  echo "Invalid action (use 'build' or 'run')."
  echo
  exit 1
fi
