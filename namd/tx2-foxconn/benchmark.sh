#!/bin/bash

set -eu
set -o pipefail

default_compiler=arm-18.3
function usage ()
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  arm-18.3"
    echo "  gcc-7.2"
    echo
    echo "The default configuration is '$default_compiler'."
    echo
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

action="$1"
export COMPILER="${2:-$default_compiler}"
charm_build_type=""

# Set up the environment
case "$COMPILER" in
    arm-18.3)
        module purge
        module load arm/hpc-compiler/18.3 cray-fftw/3.3.6.3
        ;;
    gcc-7.2)
        module purge
        module load gcc/7.2.0 cray-fftw/3.3.6.3
        ;;
    *)
        echo "Invalid compiler."
        usage
        exit 2
esac

export BENCHMARK_PLATFORM=tx2-foxconn
install_dir="$PWD/NAMD-2.12-TX2-$COMPILER-charm-6.8.2-cray-fftw-3.3.6.3"

# Handle actions
if [ "$action" == "build" ]; then
    # Perform build
    namd_dir="$PWD/NAMD_2.12_Source"
    charm_dir="$PWD/charm-v6.8.2"

    # If the sources aren't present, obtain them
    if [ ! -d "$namd_dir" ] || [ ! -d "$charm_dir" ]; then
        "$script_dir"/../fetch.sh
    fi

    # Do not continue with the build if the directory already exists
    if [ -d "$install_dir" ]; then
        echo "Installation directory already exists: $install_dir."
        echo "Stop."
        exit 4
    fi

    echo "Installing into: $install_dir"

    echo "Building Charm++..."

    charm_install_dir="$install_dir/charm682"
    mkdir -p "$charm_install_dir"
    cd "$charm_dir"

    case "$COMPILER" in
        arm-18.3)
            charmarch="multicore-linux-aarch64"
            ;;
        gcc-7.2)
            charmarch="multicore-linux64"
            ;;
        *)
            echo "Invalid compiler '$COMPILER'. This is most likely a bug in the script."
            exit 2
            ;;
    esac

    eval ./build charm++ "$charmarch" "$charm_build_type" --with-production --destination="$charm_install_dir/$charmarch" -j8

    echo
    echo "Building NAMD..."

    cd "$namd_dir"

    # Set compiler-specific options for the architecture
    case "$COMPILER" in
        arm-18.3)
            namd_target="Linux-ARM64-armclang"
            ;;
        gcc-7.2)
            namd_target="Linux-ARM64-g++"
            sed -i 's/^FLOATOPTS =.*/FLOATOPTS = -march=armv8.1-a -mcpu=thunderx2t99 -O3 -ffast-math -funsafe-math-optimizations -fomit-frame-pointer -ffp-contract=fast/' "arch/$namd_target.arch"
            ;;
        *)
            echo "Invalid compiler '$COMPILER'. This is most likely a bug in the script."
            exit 2
            ;;
    esac

    sed -i '/CHARMBASE/d' "arch/$namd_target.arch"
    echo "CHARMBASE=$charm_install_dir" >> "arch/$namd_target.arch"

    sed -i 's,^FFTDIR=.*,FFTDIR='"/opt/cray/pe/fftw/$CRAY_FFTW_VERSION/arm_thunderx2," "arch/${namd_target%-armclang}.fftw3"

    rm -rf "$namd_target"
    ./config "$namd_target" --with-fftw3 --without-tcl --charm-arch "$charmarch"
    cd "$namd_target"
    make -j16
    cp charmrun namd2 "$install_dir"

    echo
    echo "Build complete."

elif [ "$action" == "run" ]; then
    bash "$script_dir/run.job"
else
    usage
    exit 3
fi
