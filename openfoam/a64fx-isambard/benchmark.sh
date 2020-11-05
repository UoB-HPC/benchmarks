#!/bin/bash
# shellcheck disable=SC2034 disable=SC1090 disable=SC2153 disable=2154

set -eu
set -o pipefail

function setup_env()
{
    current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
    case "$COMPILER" in
        arm-20.0)
            module swap "PrgEnv-$current_env" PrgEnv-allinea
            module swap allinea allinea/20.0.0.0

            of_platform=linuxARM64Arm
            ;;
        cce-10.0)
            module swap cce cce/10.0.1

            of_platform=linuxARM64Clang
            ;;
        gcc-8.1)
            module load gcc/8.1.0 flex

            of_platform=linuxARM64Gcc
            OPT_CPPARCH="-march=armv8.3-a+sve"
            ;;
        gcc-8.3)
            module unload gcc # System default is gcc 8.3
            module load flex

            of_platform=linuxARM64Gcc
            OPT_CPPARCH="-march=armv8.3-a+sve"
            ;;
        gcc-11.0)
            module load gcc/11-20201025
            module load flex

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
        cray-mvapich2-2.3.4)
            module load cray-mvapich2_noslurm_nogpu/2.3.4
            ;;
        openmpi-4.0.4)
            case "$COMPILER" in
                gcc-8*)
                    module load openmpi/4.0.4/gcc-8.1
                    ;;
                gcc-11.0)
                    module load openmpi/4.0.4/gcc-11.0
                    ;;
                *)
                    echo "Open MPI is only supported with: gcc-8.1 gcc-11.0"
                    echo "Selected compiler: $COMPILER"
                    exit 3
                    ;;
            esac
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
export ARCH="a64fx"
export SYSTEM="isambard"
export PLATFORM="${ARCH}-${SYSTEM}"
export COMPILERS="arm-20.0 cce-10.0 gcc-8.1 gcc-8.3 gcc-11.0"
export DEFAULT_COMPILER="gcc-11.0"
export MPILIBS="cray-mvapich2-2.3.4"
export DEFAULT_MPILIB="cray-mvapich2-2.3.4"
export -f setup_env

export OPT_CC="g++ -std=c++11"
export OPT_CPPOPT="-O3 -floop-optimize -falign-loops -falign-labels -falign-functions -falign-jumps -ffast-math -ffp-contract=fast"
export OPT_CPPARCH="-mcpu=a64fx"
export OPT_NCOMPPROCS=16

export PBS_RESOURCES=":ncpus=48"

bash "$PLATFORM_DIR"/../common.sh "$@"

