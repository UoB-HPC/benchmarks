# shellcheck shell=bash

set -eu
set -o pipefail

function usage
{
    echo
    echo "Usage:"
    echo "  # Build the benchmark"
    echo "  ./benchmark.sh build [COMPILER]"
    echo
    echo "  # Run on a single node"
    echo "  ./benchmark.sh run node [COMPILER]"
    echo
    echo "Valid compilers:"
    for COMPILER in $COMPILERS
    do
      echo "  $COMPILER"
    done
    echo
    echo "The default configuration is '$DEFAULT_COMPILER'."
    echo
}

# Process arguments
if [ $# -lt 1 ]; then
  usage
  exit 1
elif [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  usage
  exit
fi


action="$1"
if [ "$action" == "run" ]
then
    shift
    RUN_ARGS="$1"
fi
export COMPILER="${2:-$DEFAULT_COMPILER}"
export CONFIG="${PLATFORM}_${COMPILER}"

SCRIPT="`realpath $0`"
SCRIPT_DIR="`realpath $(dirname $SCRIPT)`"

export SRC_DIR="$PWD/miniBUDE/openmp"
export CFG_DIR="$PWD/${PLATFORM}/${COMPILER}"
export BENCHMARK_EXE="bude"

# Set up the environment
setup_env


# Fetch source code
if ! "$SCRIPT_DIR/fetch.sh"
then
    echo
    echo "Failed to fetch source code."
    echo
    exit 1
fi

# Handle actions
if [ "$action" == "build" ]; then
  rm -f "$SRC_DIR/$BENCHMARK_EXE" "$CFG_DIR/$BENCHMARK_EXE"
  if ! eval make -C "$SRC_DIR" -B "$MAKE_OPTS" -j; then
    echo
    echo "Build failed."
    echo
    exit 1
  fi

  mkdir -p "$CFG_DIR"
  mv "$SRC_DIR/$BENCHMARK_EXE" "$CFG_DIR"
elif [ "$action" == "run" ]; then
  # Check binary exists
  if [ ! -x "$CFG_DIR/$BENCHMARK_EXE" ]; then
    echo "Executable '$CFG_DIR/$BENCHMARK_EXE' not found."
    echo "Use the 'build' action first."
    exit 1
  fi

  cd "$CFG_DIR"
  if [ "$RUN_ARGS" == node ]
  then
      NODES=1
      JOBSCRIPT=node.job
  elif [[ "$RUN_ARGS" == scale-* ]]
  then
      echo "miniBUDE does not support multi-node jobs"
      exit 7
  else
      echo
      echo "Invalid 'run' argument '$RUN_ARGS'"
      usage
      exit 1
  fi

  # Submit job
  mkdir -p "$RUN_ARGS"
  cd "$RUN_ARGS"
    qsub -l select=$NODES${PBS_RESOURCES:-} \
        -o job.out \
        -N "bude_${RUN_ARGS}_${CONFIG}" \
        -V \
        "$PLATFORM_DIR/$JOBSCRIPT"


else
  echo
  echo "Invalid action (use 'build' or 'run')."
  echo
  exit 1
fi
