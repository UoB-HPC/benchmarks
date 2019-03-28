#!/bin/bash
# shellcheck disable=SC2034 disable=SC1090

set -eu
set -o pipefail

# TODO: hypethreading parameter

default_compiler=gcc-7.3
default_mpilib=cray-mpich-7.7.6
function usage ()
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MPI-LIB]"
    echo
    echo "Valid compilers:"
    echo "  gcc-7.3"
    echo
    echo "Valid MPI libraries:"
    echo "  cray-mpich-7.7.6"
    echo "  openmpi-1.10.4"
    echo
    echo "The default configuration is '$default_compiler $default_mpilib'."
    echo
}

# Exit codes
exit_too_few_arguments=1
exit_bad_compiler=2
exit_invalid_action=3
exit_install_already_exists=4
exit_missing_code=5
exit_bad_mpilib=6
exit_not_built=7

if [ $# -lt 1 ]; then
    usage
    exit $exit_too_few_arguments
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

action="$1"
export COMPILER="${2:-$default_compiler}"
export MPILIB="${3:-$default_mpilib}"
of_platform=""

# Set up the environment
case "$COMPILER" in
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
        echo "Invalid compiler."
        usage
        exit $exit_bad_compiler
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
        echo "Invalid MPI library."
        usage
        exit $exit_bad_mpilib
        ;;
esac

export BENCHMARK_PLATFORM=tx2-isambard
install_dir="$PWD/OpenFOAM-v1712-TX2-$COMPILER-$MPILIB"

# Handle actions
if [ "$action" == "build" ]; then
    # Perform build
    [ ! -d "$install_dir" ] && mkdir "$install_dir"

    echo "Installing into: $install_dir"
    tgz_of="OpenFOAM-v1712.tgz"
    tgz_tp="ThirdParty-v1712.tgz"

    # Fetch the code if necessary
    if [ ! -f "$tgz_of" ] || [ ! -f "$tgz_tp" ]; then
        "$script_dir"/../fetch.sh
    fi

    # Unpack the source code into the install path if it's not already there
    dir_of="$install_dir/${tgz_of%.tgz}"
    dir_tp="$install_dir/${tgz_tp%.tgz}"
    if [ -d "$dir_of" ] && [ -n "$(ls -A "$dir_of")" ]; then
        echo "OpenFOAM is already unpacked."
    else
        echo "Unzipping $tgz_of..."
        tar -xf "$tgz_of" -C "$install_dir"
    fi
    if [ -d "$dir_tp" ] && [ -n "$(ls -A "$dir_tp")" ]; then
        echo "ThirdParty is already unpacked."
    else
        echo "Unzipping $tgz_tp..."
        tar -xf "$tgz_tp" -C "$install_dir"
    fi

    # Copy modified build files
    if [[ "$MPILIB" =~ mpich ]]; then
        case "$COMPILER" in
            gcc-*)
                echo "Copy gnu-mpich build parts: $script_dir/../build-parts/tx2-isambard ->  $install_dir"
                cp -r "$script_dir"/../build-parts/tx2-isambard/* "$install_dir"
                ;;
        esac
    fi

    pushd "$install_dir/OpenFOAM-v1712"
    bashrc="etc/bashrc"
    cflags="wmake/rules/$of_platform/c"
    cppflags="wmake/rules/$of_platform/c++"
    cppOptflags="wmake/rules/$of_platform/c++Opt"

    # Set the installtion directory path and the MPI library
    sed -i 's,^FOAM_INST_DIR=.*,FOAM_INST_DIR='"$PWD," "$bashrc"
    case "$MPILIB" in
        cray-mpich-*)
            sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=CRAY-MPICH,' "$bashrc"
            ;;
        openmpi-1.10.4)
            sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=OPENMPI,' "$bashrc"
            ;;
        *)
            echo "Invalid MPI library '$MPILIB'. This is most likely a bug in the script."
            exit $exit_bad_mpilib
            ;;
    esac

    # Set the compiler and flags
    case "$COMPILER" in
        gcc-*)
            sed -i 's,^export WM_COMPILER=.*,export WM_COMPILER=Gcc,' "$bashrc"
            sed -i '/export WM_COMPILER=Gcc/a export CRAYPE_LINK_TYPE=dynamic' "$bashrc"
            sed -i 's/^CC          =.*/CC          = CC -std=c++11/' "$cppflags"
            sed -i 's/^c++OPT      =.*/c++OPT      = -march=armv8.1-a -mtune=thunderx2t99 -mcpu=thunderx2t99 -O3 -ffast-math/' "$cppOptflags"
            ;;
        *)
            echo "Invalid compiler '$COMPILER'. This is most likely a bug in the script."
            exit $exit_bad_compiler
            ;;
    esac

    cat >>"$cppOptflags" <<EOF
# Suppress some warnings for flex++ and CGAL
c++LESSWARN = -Wno-old-style-cast -Wno-unused-local-typedefs -Wno-array-bounds -fpermissive
EOF

    # Disable -eu because otherwise sourcing bashrc will trigger it
    set +e +u
    source "$bashrc"

    # Additional flag changes: enable parallel compilation and remove `m64`, which Cray systems don't like
    export WM_NCOMPPROCS=16

    time ./Allwmake |& tee "build_${COMPILER}_${MPILIB}.log"

    # Create a test case directory if the files are available (and the directory doesn't exist already)
    popd
    testdir="run/block_DrivAer_small-$BENCHMARK_PLATFORM"
    if [ -d "$testdir" ]; then
        echo "Test directory already exists: $testdir"
    elif [ -f OpenFOAM-v1712-block_DrivAer_small.tar.gz ]; then
        mkdir -p "$testdir"
        tar -xf OpenFOAM-v1712-block_DrivAer_small.tar.gz -C "$testdir" --strip-components 1
    elif [ -d OpenFOAM-v1712-block_DrivAer_small ]; then
        mkdir -p "$testdir"
        cp -r OpenFOAM-v1712-block_DrivAer_small "$testdir"
    else
        echo "Test case direcotry not available. You will have to obtain and unpack the test case manually before running the benchmark."
    fi

    echo
    echo "Build complete."

elif [ "$action" == "run" ]; then
    if [ ! -d "OpenFOAM-v1712-TX2-$COMPILER-$MPILIB" ]; then
        echo "Configuration not built: $COMPILER $MPILIB"
        echo "Have you run 'benchmark.sh build $COMPILER $MPILIB'?"
        exit $exit_not_built
    fi

    qsub -V \
        -o "OpenFOAM-$BENCHMARK_PLATFORM-$COMPILER-$MPILIB.out" \
        "$script_dir/run.job" 
else
    usage
    exit $exit_invalid_action
fi
