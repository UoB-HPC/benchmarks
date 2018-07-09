#!/bin/bash
# shellcheck disable=SC2034

set -eu
set -o pipefail

default_compiler=gcc-7.3
function usage ()
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER]"
    echo
    echo "Valid compilers:"
    echo "  gcc-7.3"
    echo "  intel-2018"
    echo
    echo "The default configuration is '$default_compiler'."
    echo
}

# Exit codes
exit_too_few_arguments=1
exit_bad_compier=2
exit_invalid_action=3
exit_install_already_exists=4
exit_missing_code=5
exit_bad_fftlib=6
exit_not_built=7

if [ $# -lt 1 ]; then
    usage
    exit $exit_too_few_arguments
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

action="$1"
export COMPILER="${2:-$default_compiler}"
charm_build_type=""

# Set up the environment
case "$COMPILER" in
    gcc-7.3)
        current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
        module swap "PrgEnv-$current_env" PrgEnv-gnu
        module swap "craype-$CRAY_CPU_TARGET" craype-broadwell
        module load cray-fftw/3.3.6.3
        module load craype-hugepages8M
        ;;
    intel-2018)
        current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
        module swap "PrgEnv-$current_env" PrgEnv-intel
        module swap intel intel/18.0.0.128
        module swap "craype-$CRAY_CPU_TARGET" craype-broadwell
        module load cray-fftw/3.3.6.3
        module load craype-hugepages8M

        charm_build_type="iccstatic"
        ;;
    *)
        echo "Invalid compiler."
        usage
        exit $exit_bad_compier
esac

export BENCHMARK_PLATFORM=bdw-swan
install_dir="$PWD/NAMD-2.12-BDW-$COMPILER-charm-6.8.2-cray-fftw-3.3.6.3"

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
        exit $exit_install_already_exists
    fi

    echo "Installing into: $install_dir"

    echo "Building Charm++..."

    charm_install_dir="$install_dir/charm682"
    mkdir -p "$charm_install_dir"
    cd "$charm_dir"

    charmarch="multicore-linux64"
    eval ./build charm++ "$charmarch" "$charm_build_type" --with-production --destination="$charm_install_dir/$charmarch" -j8

    echo
    echo "Building NAMD..."

    cd "$namd_dir"

    # Set compiler-specific options for the architecture
    case "$COMPILER" in
        gcc-7.3)
            namd_target="Linux-x86_64-g++"
            sed -i 's/-m64//' "arch/$namd_target.arch"
            sed -i 's/-march=[^ ]*//g' "arch/$namd_target.arch"
            sed -i '/^C\(\|XX\)OPTS.*/ s/$/ -march=core-avx2/' "arch/$namd_target.arch"
            ;;
        intel-2018)
            namd_target="Linux-x86_64-icc"
            sed -i 's/-O2/-O3/g' "arch/$namd_target.arch"
            sed -r -i '/^FLOATOPTS/ s/-a?x[^ ]+/-xCORE-AVX2/' "arch/$namd_target.arch"
            sed -i 's,^CHARMARCH =.*,CHARMARCH = '"$charmarch," "arch/$namd_target.arch"
            ;;
        *)
            echo "Invalid compiler '$COMPILER'. This is most likely a bug in the script."
            exit $exit_bad_compier
        ;;
    esac

    sed -i '/CHARMBASE/d' "arch/$namd_target.arch"
    echo "CHARMBASE=$charm_install_dir" >> "arch/$namd_target.arch"

    fftw3_dir="$(readlink -f "$FFTW_DIR/..")"
    sed -i 's,^FFTDIR=.*,FFTDIR='"$fftw3_dir," arch/Linux-x86_64.fftw3

    rm -rf "$namd_target"
    ./config "$namd_target" --with-fftw3 --without-tcl --charm-arch "$charmarch"
    cd "$namd_target"
    make -j8
    cp charmrun namd2 "$install_dir"

    echo
    echo "Build complete."

elif [ "$action" == "run" ]; then
    if [ ! -d "NAMD-2.12-BDW-$COMPILER-charm-6.8.2-cray-fftw-3.3.6.3" ]; then
        echo "Configuration not built: $COMPILER"
        echo "Have you run 'benchmark.sh build $COMPILER'?"
        exit $exit_not_built
    fi

    qsub "$script_dir/run.job" \
        -o "NAMD-$BENCHMARK_PLATFORM-$COMPILER.out" \
        -V
else
    usage
    exit $exit_invalid_action
fi
