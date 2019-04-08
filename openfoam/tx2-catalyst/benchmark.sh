#!/bin/bash
# shellcheck disable=SC2034 disable=SC1090 disable=SC2153 disable=2154

set -eu
set -o pipefail

function setup_env()
{
    module purge
    case "$COMPILER" in
        gcc-7.1)
            module load Generic-AArch64/SUSE/12/gcc/7.1.0
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
        hmpt-2.20)
            case "$COMPILER" in
                gcc-7.1)
                    module load hmpt/2.20-gcc-7.1.0
                    ;;
            *)
                echo
                echo "Invalid compiler."
                usage
                exit 1
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
export ARCH=tx2
export SYSTEM=catalyst
export PLATFORM="${ARCH}-${SYSTEM}"
export COMPILERS="gcc-7.1"
export DEFAULT_COMPILER=gcc-7.1
export MPILIBS="hmpt-2.20 openmpi-1.10.4"
export DEFAULT_MPILIB=hmpt-2.20
export -f setup_env

export OPT_CPPOPT="-march=armv8.1-a -mtune=thunderx2t99 -mcpu=thunderx2t99 -O3 -ffast-math"
export OPT_NCOMPPROCS=16

export PBS_RESOURCES=":ncpus=64:mpiprocs=64:ompthreads=1"

bash "$PLATFORM_DIR"/../common.sh "$@"

