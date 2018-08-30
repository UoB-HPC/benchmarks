#!/bin/bash

DEFAULT_COMPILER=cce-8.6
function usage
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  cce-8.6"
    echo "  cce-8.7"
    echo "  gcc-7.2"
    echo "  arm-18.3"
    echo "  arm-18.4"
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

export CONFIG="tx2"_"$COMPILER"
export SRC_DIR=$PWD/um-amip
export CFG_DIR=$PWD/um-$CONFIG
export BUILD_DIR=$CFG_DIR/build


# Set up the environment
case "$COMPILER" in
    cce-8.6)
        module swap cce cce/8.6.4
        TOOLCHAIN=cce
        ;;
    cce-8.7)
        module swap cce cce/8.7.0
        TOOLCHAIN=cce
        ;;
    gcc-7.2)
        module purge
        module load gcc/7.2.0
        module load mpich/3.2/gcc-7.2
        TOOLCHAIN=gnu

        export FCM_CPP=${FCM_CPP:-gcc}
        export FCM_FPP=${FCM_FPP:-gcc}
        export FCM_CC=${FCM_CC:-gcc}
        export FCM_FTN=${FCM_FTN:-gfortran}
        export FCM_MPICC=${FCM_MPICC:-mpicc}
        export FCM_MPIFTN=${FCM_MPIFTN:-mpifort}
        ;;
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3
        module load openmpi/3.0.0/arm-18.3
        TOOLCHAIN=arm

        export FCM_CPP=${FCM_CPP:-armclang}
        export FCM_FPP=${FCM_FPP:-cpp}
        export FCM_CC=${FCM_CC:-armclang}
        export FCM_FTN=${FCM_FTN:-mpifort}
        export FCM_MPICC=${FCM_MPICC:-mpicc}
        export FCM_MPIFTN=${FCM_MPIFTN:-mpifort}
        ;;
    arm-18.4)
        module purge
        module load arm/hpc-compiler/18.4
        module load openmpi/3.0.0/arm-18.4
        TOOLCHAIN=arm

        export FCM_CPP=${FCM_CPP:-armclang}
        export FCM_FPP=${FCM_FPP:-cpp}
        export FCM_CC=${FCM_CC:-armclang}
        export FCM_FTN=${FCM_FTN:-mpifort}
        export FCM_MPICC=${FCM_MPICC:-mpicc}
        export FCM_MPIFTN=${FCM_MPIFTN:-mpifort}
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

    export PATH=$PWD/fcm/bin:$PATH

    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    export LIBDIR_ROOT=$PWD/shumlib
    export LIBDIR_OUT=$PWD/shumlib
    export DIR_ROOT=$SRC_DIR/shumlib

    mkdir -p ${LIBDIR_OUT}
    mkdir -p ${DIR_ROOT}/shum_thread_utils/src
    mkdir -p ${DIR_ROOT}/shum_latlon_eq_grids/src
    mkdir -p ${DIR_ROOT}/shum_data_conv/src
    mkdir -p ${DIR_ROOT}/shum_byteswap/src
    mkdir -p ${DIR_ROOT}/fruit

    echo -e "clean:" > ${DIR_ROOT}/shum_thread_utils/src/Makefile
    echo -e "clean:" > ${DIR_ROOT}/shum_latlon_eq_grids/src/Makefile
    echo -e "clean:" > ${DIR_ROOT}/shum_data_conv/src/Makefile
    echo -e "clean:" > ${DIR_ROOT}/shum_byteswap/src/Makefile
    echo -e "clean:" > ${DIR_ROOT}/fruit/Makefile
    echo -e "clean:" > ${DIR_ROOT}/fruit/Makefile-driver

    make -f $SCRIPT_DIR/$TOOLCHAIN/shumlib.mk clean
    make -f $SCRIPT_DIR/$TOOLCHAIN/shumlib.mk shum_wgdos_packing shum_string_conv

    if ! fcm make -f $SCRIPT_DIR/$TOOLCHAIN/drhook.cfg -v -j 256
    then
        echo
        echo "Building drhook failed."
        echo
        exit 1
    fi

    if ! fcm make -f $SCRIPT_DIR/$TOOLCHAIN/gcom.cfg -v -j 256
    then
        echo
        echo "Building gcom failed."
        echo
        exit 1
    fi

    if ! fcm make -f $SCRIPT_DIR/$TOOLCHAIN/fcm-make.cfg -v -j 256
    then
        echo
        echo "Build amip failed."
        echo
        exit 1
    fi

elif [ "$ACTION" == "run" ]
then
    if [ ! -x "$BUILD_DIR/build-atmos/bin/um-atmos.exe" ]
    then
        echo "Executable '$BUILD_DIR/build-atmos/bin/um-atmos.exe' not found."
        echo "Use the 'build' action first."
        exit 1
    fi

    cd $CFG_DIR
    bash $SCRIPT_DIR/run.job
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi
