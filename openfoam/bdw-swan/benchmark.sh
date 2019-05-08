#!/bin/bash
# shellcheck disable=SC2034 disable=SC1090 disable=SC2153 disable=2154

set -eu
set -o pipefail

function setup_env()
{
    case "$COMPILER" in
        gcc-7.3)
            current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
            module swap "PrgEnv-$current_env" PrgEnv-gnu
            module swap "craype-$CRAY_CPU_TARGET" craype-broadwell
            module swap gcc gcc/7.3.0
            module load cray-fftw/3.3.6.3
            module load craype-hugepages8M

            of_platform=linux64Gcc
            ;;
        intel-2018)
            current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
            module swap "PrgEnv-$current_env" PrgEnv-intel
            module swap intel intel/18.0.0.128
            module swap "craype-$CRAY_CPU_TARGET" craype-broadwell
            module load cray-fftw/3.3.6.3
            module load craype-hugepages8M

            of_platform=linux64Icc
            ;;
        intel-2019)
            current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
            module swap "PrgEnv-$current_env" PrgEnv-intel
            module swap intel intel/19.0.3.199
            module swap "craype-$CRAY_CPU_TARGET" craype-broadwell
            module load cray-fftw/3.3.8.2
            module load craype-hugepages8M

            of_platform=linux64Icc
            ;;
        *)
            echo "Invalid compiler."
            usage
            exit 1
            ;;
    esac

    case "$MPILIB" in
        cray-mpich-7.7.6)
            module swap cray-mpich cray-mpich/7.7.6
            ;;
        openmpi-1.10.4)
            # No action required
            ;;
        *)
            echo "Invalid MPI library."
            usage
            exit 1
            ;;
    esac
}

# This function will be called after sourcing the OpenFOAM environment setup functions
function override_env() {
    export WM_CFLAGS='-fPIC' WM_CXXFLAGS='-fPIC -std=c++11' WM_LDFLAGS=''    
}

script="$(realpath "$0")"
export PLATFORM_DIR="$(realpath "$(dirname "$script")")"
export ARCH=bdw
export SYSTEM=swan
export PLATFORM="${ARCH}-${SYSTEM}"
export COMPILERS="gcc7-3 intel-2018"
export DEFAULT_COMPILER=gcc-7.3
export MPILIBS="cray-mpich-7.7.6 openmpi-1.10.4"
export DEFAULT_MPILIB=cray-mpich-7.7.6
export -f setup_env

export OPT_CC="CC -std=c++11"
export OPT_NCOMPPROCS=8
export -f override_env

export PBS_RESOURCES=":ncpus=44"

bash "$PLATFORM_DIR"/../common.sh "$@"

