#!/bin/bash

set -u

function usage
{
    echo
    echo "Usage:"
    echo "  # Build the benchmark"
    echo "  ./benchmark.sh build [COMPILER] [FFT-LIB]"
    echo
    echo "  # Run on a single node"
    echo "  ./benchmark.sh run node [COMPILER] [FFT-LIB]"
    echo
    echo "  # Run on N nodes"
    echo "  ./benchmark.sh run scale-N [COMPILER] [FFT-LIB]"
    echo
    echo "Valid compilers:"
    for compiler in $COMPILERS
    do
      echo "  $compiler"
    done
    echo
    echo "Valid FFT libraries:"
    for fftlib in $FFTLIBS
    do
      echo "  $fftlib"
    done
    echo
    echo "The default configuration is '$DEFAULT_COMPILER $DEFAULT_FFTLIB'."
    echo
}

# Process arguments
if [ $# -lt 1 ]
then
    usage
    exit 1
fi

ACTION=$1
if [ "$ACTION" == "run" ]
then
    shift
    RUN_ARGS=$1
fi
COMPILER=${2:-$DEFAULT_COMPILER}
FFTLIB=${3:-$DEFAULT_FFTLIB}
SCRIPT=`realpath $0`
SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export CONFIG="$ARCH"_"$COMPILER"_"$FFTLIB"
export SRC_DIR=$PWD/gromacs-2018.5
export CFG_DIR=$PWD/gromacs/"$ARCH"/"$COMPILER"_"$FFTLIB"
export BUILD_DIR=$CFG_DIR/build
export BENCHMARK_NODE=$PWD/gromacs-benchmarks/benchmarks/ion_channel_vsites.bench/pme-runs/topol.tpr
export BENCHMARK_SCALE=$PWD/nsteps800.tpr

# Set up the environment
setup_env

# Handle actions
if [ "$ACTION" == "build" ]
then
    # Fetch source code
    if ! "$SCRIPT_DIR/fetch.sh"
    then
        echo
        echo "Failed to fetch source code."
        echo
        exit 1
    fi

    rm -rf $BUILD_DIR
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR

    # Configure with CMake
    if ! eval cmake $SRC_DIR -DCMAKE_BUILD_TYPE=Release \
        -DGMX_CYCLE_SUBCOUNTERS=ON \
        -DGMX_MPI=ON -DGMX_GPU=OFF -DGMX_DOUBLE=OFF \
        $CMAKE_OPTS
    then
        echo
        echo "Running CMake failed."
        echo
        exit 1
    fi

    # Perform build
    if ! make -j 8
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$BUILD_DIR/bin/gmx_mpi" ]
    then
        echo "Executable '$BUILD_DIR/bin/gmx_mpi' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    cd $CFG_DIR

    if [ "$RUN_ARGS" == node ]
    then
        NODES=1
        JOBSCRIPT=node.job
    elif [[ "$RUN_ARGS" == scale-* ]]
    then
        export NODES=${RUN_ARGS#scale-}
        if ! [[ "$NODES" =~ ^[0-9]+$ ]]
        then
            echo
            echo "Invalid node count for 'run scale-N' action"
            echo
            exit 1
        fi
        JOBSCRIPT=scale.job

        # Check for scaling input (requires manual download)
        if [ ! -r "$BENCHMARK_SCALE" ]
        then
            echo
            echo "Benchmark input '$BENCHMARK_SCALE' not found."
            echo "Download it from this URL:"
            echo "  https://datasync.ed.ac.uk/index.php/s/49Qg4UVsYE2EjvL"
            echo "Password: gromacs"
            echo
            exit 1
        fi
    else
        echo
        echo "Invalid 'run' argument '$RUN_ARGS'"
        usage
        exit 1
    fi

    # Submit job
    mkdir -p $RUN_ARGS
    cd $RUN_ARGS
    qsub -l select=$NODES$PBS_RESOURCES \
        -o job.out \
        -N gromacs_"$CONFIG" \
        -V \
        $PLATFORM_DIR/$JOBSCRIPT
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
