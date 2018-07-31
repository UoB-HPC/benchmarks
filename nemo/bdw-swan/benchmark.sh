#!/bin/bash

DEFAULT_COMPILER=cce-8.7
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.7"
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
SCRIPT=`realpath $0`
export SCRIPT_DIR=`realpath $(dirname $SCRIPT)`

export CONFIG="bdw"_"$COMPILER"
export SRC_DIR=$PWD/NEMOGCM
export RUN_DIR=$PWD/NEMOGCM/cfgs/$CONFIG/EXP00


# Set up the environment
case "$COMPILER" in
    cce-8.7)
        module swap cce cce/8.7.1
        module load cray-netcdf
        export CPP=cpp
        export FC=ftn
        export LD=ftn
        export CC=cc
        export FCFLAGS="-em -s real64 -s integer32  -O2 -hflex_mp=intolerant -e0 -ez"
        export FFLAGS="-em -s real64 -s integer32  -O0 -hflex_mp=strict -e0 -ez -Rb"
        export FPPFLAGS="-P -E -traditional-cpp"
        export LDFLAGS="-hbyteswapio"
        export CFLAGS="-O0"
        ;;
    *)
        echo
        echo "Invalid compiler '$COMPILER'."
        usage
        exit 1
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

    # Generate arch config file
    envsubst <"$SCRIPT_DIR/../template.fcm" >"$SRC_DIR/arch/arch-$CONFIG.fcm"

    # Perform build
    if ! "$SRC_DIR/makenemo" -r GYRE_PISCES -m "$CONFIG" -n "$CONFIG" -j 1 del_key "key_iomput" add_key "key_nosignedzero"
    then
        echo
        echo "Build failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$RUN_DIR/nemo" ]
    then
        echo "Executable '$RUN_DIR/nemo' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    qsub $SCRIPT_DIR/run.job \
        -d $RUN_DIR \
        -o $PWD/nemo-$CONFIG.out \
        -N nemo \
        -V
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
