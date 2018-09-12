#!/bin/bash
# shellcheck disable=SC2034 disable=SC1090

set -eu
set -o pipefail

# TODO: hypethreading parameter

default_compiler=gcc-7.2
default_mpilib=openmpi-3.0.0
function usage ()
{
    echo
    echo "Usage: ./benchmark.sh build|run [COMPILER] [MPI-LIB]"
    echo
    echo "Valid compilers:"
    echo "  arm-18.3"
    echo "  arm-18.4"
    echo "  gcc-7.2"
    echo "  gcc-8.1"
    echo
    echo "Valid MPI libraries:"
    echo "  openmpi-1.10.4"
    echo "  openmpi-3.0.0"
    echo "  openmpi-3.1.0"
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
module purge
case "$COMPILER" in
    gcc-7.2)
        module load gcc/7.2.0

        of_platform=linuxARM64Gcc
        ;;
    gcc-7.1)
        module load gcc/8.1.0

        of_platform=linuxARM64Gcc
        ;;
    arm-18.3)
        module load arm/hpc-compiler/18.3

        of_platform=linuxARM64Arm
        ;;
    arm-18.4)
        module load arm/hpc-compiler/18.4

        of_platform=linuxARM64Arm
        ;;
    *)
        echo "Invalid compiler."
        usage
        exit $exit_bad_compiler
        ;;
esac

case "$MPILIB" in
    openmpi-1.10.4)
        # No action required
        ;;
    openmpi-3.0.0)
        case "$COMPILER" in
            arm-18.3)
                module load openmpi/3.0.0/arm-18.3
                ;;
            arm-18.4)
                module load openmpi/3.0.0/arm-18.4
                ;;
            gcc-7.2)
                module load openmpi/3.0.0/gcc-7.2
                ;;
            gcc-8.1)
                module load openmpi/3.0.0/gcc-8.1
                ;;
            *)
                echo "Invalid compiler '$COMPILER'. This is most likely a bug in the script."
                exit $exit_bad_compiler
                ;;
        esac
        ;;
    openmpi-3.1.0)
        case "$COMPILER" in
            arm-*)
                module load openmpi/3.1.0/arm-18.3
                ;;
            gcc-*)
                module load openmpi/3.1.0/gcc-8.1
                ;;
            *)
                echo "Invalid compiler '$COMPILER'. This is most likely a bug in the script."
                exit $exit_bad_compiler
                ;;
        esac
        ;;
    *)
        echo "Invalid MPI library."
        usage
        exit $exit_bad_mpilib
        ;;
esac

export BENCHMARK_PLATFORM=tx2-foxconn
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
        cp -r "$script_dir"/../build-parts/common-gnu-mpich/* "$install_dir"
    fi

    pushd "$install_dir/OpenFOAM-v1712"
    bashrc="etc/bashrc"
    cflags="wmake/rules/$of_platform/c"
    cppflags="wmake/rules/$of_platform/c++"
    cOptflags="wmake/rules/$of_platform/cOpt"
    cppOptflags="wmake/rules/$of_platform/c++Opt"

    # Set the installtion directory path and the MPI library
    sed -i '/^FOAM_INST_DIR=.*/a FOAM_INST_DIR='"$(dirname "$PWD")" "$bashrc"
    case "$MPILIB" in
        cray-mpich-*)
            sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=CRAY-MPICH,' "$bashrc"
            ;;
        openmpi-1.10.4)
            sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=OPENMPI,' "$bashrc"
            ;;
        openmpi-3*)
            sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=SYSTEMOPENMPI,' "$bashrc"
            ;;
        *)
            echo "Invalid MPI library '$MPILIB'. This is most likely a bug in the script."
            exit $exit_bad_mpilib
            ;;
    esac

    # Set the compiler and flags
    case "$COMPILER" in
        arm-*)
            wmake_gcc="wmake/rules/linuxARM64Gcc"
            wmake_arm="wmake/rules/linuxARM64Arm"
            cp -r "$wmake_gcc" "$wmake_arm"

            sed -i 's/^cc          =.*/cc          = armclang/' "$cflags"
            sed -i 's/^CC          =.*/CC          = armclang++ -std=c++11/' "$cppflags"
            sed -i 's/^export WM_COMPILER=.*/export WM_COMPILER=Arm/' "$bashrc"
            sed -i 's/^cOPT        =.*/cOPT        = -mcpu=thunderx2t99 -O3 -ffast-math/' "$cOptflags"
            sed -i 's/^c++OPT      =.*/c++OPT      = -mcpu=thunderx2t99 -O3 -ffast-math/' "$cppOptflags"

            # Apply required source changes: https://gitlab.com/arm-hpc/packages/wikis/packages/openfoamplus
            ( cd src/finiteVolume/finiteVolume/ddtSchemes/CrankNicolsonDdtScheme/;
cat <<EOPATCH | patch -p1
--- a/CrankNicolsonDdtScheme.C
+++ b/CrankNicolsonDdtScheme.C
@@ -101,7 +101,7 @@ operator=(const GeoField& gf)

 template<class Type>
 template<class GeoField>
-CrankNicolsonDdtScheme<Type>::DDt0Field<GeoField>&
+typename CrankNicolsonDdtScheme<Type>::template DDt0Field<GeoField>&
 CrankNicolsonDdtScheme<Type>::ddt0_
 (
     const word& name,

EOPATCH
            )
            ;;
        gcc-*)
            sed -i 's,^export WM_COMPILER=.*,export WM_COMPILER=Gcc,' "$bashrc"
            sed -i 's/^c++OPT      =.*/c++OPT      = -march=armv8.1-a -mtune=thunderx2t99 -mcpu=thunderx2t99 -O3 -ffast-math/' "$cppflags"
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
    export WM_NCOMPPROCS=64

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

    bash "$script_dir/run.job"
else
    usage
    exit $exit_invalid_action
fi
