#!/bin/bash
# shellcheck disable=SC2034 disable=SC1090 disable=SC2153 disable=2154

set -eu
set -o pipefail

function setup_env()
{
    case "$COMPILER" in
        arm-19.0)
            current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
            module swap "PrgEnv-$current_env" PrgEnv-allinea
            if [ -n "${CRAY_CPU_TARGET:-}" ]; then
                module swap "craype-$CRAY_CPU_TARGET" craype-arm-thunderx2
            else
                module load craype-arm-thunderx2
            fi
            module swap allinea allinea/19.0.0.1
            module load cray-fftw/3.3.8.2
            module load craype-hugepages8M

            of_platform=linuxARM64Arm
            ;;
        arm-19.2)
            module load cdt/19.08 &>/dev/null

            current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
            module swap "PrgEnv-$current_env" PrgEnv-allinea
            if [ -n "${CRAY_CPU_TARGET:-}" ]; then
                module swap "craype-$CRAY_CPU_TARGET" craype-arm-thunderx2
            else
                module load craype-arm-thunderx2
            fi
            module swap allinea allinea/19.2.0.0
            module load cray-fftw/3.3.8.3
            module load craype-hugepages8M

            of_platform=linuxARM64Arm
            ;;
        gcc-7.3)
            current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
            module swap "PrgEnv-$current_env" PrgEnv-gnu
            if [ -n "${CRAY_CPU_TARGET:-}" ]; then
                module swap "craype-$CRAY_CPU_TARGET" craype-arm-thunderx2
            else
                module load craype-arm-thunderx2
            fi
            module swap gcc gcc/7.3.0
            module load cray-fftw/3.3.8.2
            module load craype-hugepages8M

            of_platform=linuxARM64Gcc
            ;;
        *)
            echo
            echo "Invalid compiler."
            usage
            exit 1
            ;;
    esac

    case "$MPILIB" in
        cray-mpich-7.7.6)
            module swap cray-mpich cray-mpich/7.7.6
            module load pmi-lib
            ;;
        openmpi-1.10.4)
            # No action required
            ;;
        *)
            echo
            echo "Invalid MPI library."
            usage
            exit 1
            ;;
    esac
}

script="$(realpath "$0")"
export PLATFORM_DIR="$(realpath "$(dirname "$script")")"
export ARCH=tx2
export SYSTEM=isambard
export PLATFORM="${ARCH}-${SYSTEM}"
export COMPILERS="arm-19.0 arm-19.2 gcc-7.3"
export DEFAULT_COMPILER=gcc-7.3
export MPILIBS="cray-mpich-7.7.6 openmpi-1.10.4"
export DEFAULT_MPILIB=cray-mpich-7.7.6
export -f setup_env

export OPT_CC="CC -std=c++11"
export OPT_CPPOPT="-march=armv8.1-a -mtune=thunderx2t99 -mcpu=thunderx2t99 -O3 -ffast-math"
export OPT_NCOMPPROCS=16

export PBS_RESOURCES=":ncpus=64"

bash "$PLATFORM_DIR"/../common.sh "$@"

