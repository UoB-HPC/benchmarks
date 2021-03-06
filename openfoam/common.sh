#!/bin/bash
# shellcheck disable=1090 disable=2153

set -eu

function usage
{
    echo
    echo "Usage:"
    echo "  # Build the benchmark"
    echo "  ./benchmark.sh build [COMPILER] [MPI-LIB]"
    echo
    echo "  # Run on a single node"
    echo "  ./benchmark.sh run node [COMPILER] [MPI-LIB]"
    echo
    echo "  # Run on N nodes"
    echo "  ./benchmark.sh run scale-N [COMPILER] [MPI-LIB]"
    echo
    echo "Valid compilers:"
    for compiler in $COMPILERS; do
      echo "  $compiler"
    done
    echo
    echo "Valid MPI libraries:"
    for mpilib in $MPILIBS; do
      echo "  $mpilib"
    done
    echo
    echo "The default configuration is '$DEFAULT_COMPILER $DEFAULT_MPILIB'."
    echo
}

# Process arguments
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

action="$1"
if [ "$action" == "run" ]; then
    shift
    if [ -z "${1:-}" ]; then
        usage
        exit 1
    fi

    run_args="$1"
fi
export COMPILER="${2:-$DEFAULT_COMPILER}"
export MPILIB="${3:-$DEFAULT_MPILIB}"
script="$(realpath "$0")"
script_dir="$(realpath "$(dirname "$script")")"

export CONFIG="${ARCH}_${COMPILER}"
export RUN_DIR="$PWD/run"
export INSTALL_DIR="$PWD/OpenFOAM-v2006-${ARCH}-${COMPILER}-${MPILIB}"

continue_build=no
restart_build=no

# Set up the environment
setup_env

# Handle actions
if [ "$action" == "build" ]; then
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir "$INSTALL_DIR"
    else
        echo "Directory already exists: $INSTALL_DIR"
        read -r -p "Proceed? (A)bort, (c)ontinue build, (r)estart build: [A] "
        case "$REPLY" in
            c*|C*)
                continue_build=yes
                ;;
            r*|R*)
                restart_build=yes
                ;;
            *)
                echo "Abort."
                exit
                ;;
        esac
    fi

    echo "Installing into: $INSTALL_DIR"
    tgz_of="OpenFOAM-v2006.tgz"
    tgz_tp="ThirdParty-v2006.tgz"

    # Fetch the code if necessary
    if [ ! -f "$tgz_of" ] || [ ! -f "$tgz_tp" ]; then
        "$script_dir"/fetch.sh
    fi

    # Unpack the source code into the install path if it's not already there
    dir_of="$INSTALL_DIR/${tgz_of%.tgz}"
    dir_tp="$INSTALL_DIR/${tgz_tp%.tgz}"
    if [ -d "$dir_of" ] && [ -n "$(ls -A "$dir_of")" ]; then
        echo "OpenFOAM is already unpacked."
    else
        echo "Unzipping $tgz_of..."
        tar -xf "$tgz_of" -C "$INSTALL_DIR"
    fi
    if [ -d "$dir_tp" ] && [ -n "$(ls -A "$dir_tp")" ]; then
        echo "ThirdParty is already unpacked."
    else
        echo "Unzipping $tgz_tp..."
        tar -xf "$tgz_tp" -C "$INSTALL_DIR"
    fi

    # Copy modified build files
    if [[ "$MPILIB" =~ mpich ]]; then
        case "$COMPILER" in
            gcc-*)
                if [ -d "${script_dir}/build-parts/gcc/${PLATFORM}/" ]; then
                    echo "Copy gcc-specific build parts: $script_dir/build-parts/gcc/$PLATFORM ->  $INSTALL_DIR"
                    cp -r "${script_dir}/build-parts/gcc/${PLATFORM}/"* "$INSTALL_DIR"
                fi
                ;;
            intel-*)
                if [ -d "${script_dir}/build-parts/intel/${PLATFORM}/" ]; then
                    echo "Copy gcc-specific build parts: $script_dir/build-parts/intel/$PLATFORM ->  $INSTALL_DIR"
                    cp -r "${script_dir}/build-parts/intel/${PLATFORM}/"* "$INSTALL_DIR"
                fi
                ;;
        esac
    fi

    pushd "$INSTALL_DIR/OpenFOAM-v2006"
    bashrc="etc/bashrc"
    cflags="wmake/rules/$of_platform/c"
    cOptflags="wmake/rules/$of_platform/cOpt"
    cppflags="wmake/rules/$of_platform/c++"
    cppOptflags="wmake/rules/$of_platform/c++Opt"
    mpiflags="etc/config.sh/mpi"
    systemopenmpiflags="wmake/rules/General/mplibSYSTEMOPENMPI"
    craympichflags="wmake/rules/General/mplibCRAY-MPICH"
    mvapich2flags="wmake/rules/General/mplibMVAPICH2"

    # Set the installtion directory path and the MPI library
    # sed -i 's,^FOAM_INST_DIR=.*,FOAM_INST_DIR='"$PWD," "$bashrc"
    sed -i '/^FOAM_INST_DIR=.*/a FOAM_INST_DIR='"$(dirname "$PWD")" "$bashrc"
    sed -i '/^# projectDir="\/usr\/local/a projectDir='"$PWD" "$bashrc"
    case "$MPILIB" in
        cray-mpich-*)
            sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=CRAY-MPICH,' "$bashrc"
            echo 'PLIBS = -L$(MPI_ARCH_PATH)/lib$(WM_COMPILER_LIB_ARCH) -L$(MPI_ARCH_PATH)/lib -lmpich -lrt' >> "$craympichflags"
            ;;
        cray-mvapich2-*)
            sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=MVAPICH2,' "$bashrc"
            echo "PINC  = -I/opt/cray/pe/cray-mvapich2_noslurm_nogpu/2.3.4/infiniband/cray/10.0/include" > "$mvapich2flags"
            echo "PLIBS = -L/opt/cray/pe/cray-mvapich2_noslurm_nogpu/2.3.4/infiniband/cray/10.0/lib -lmpi" >> "$mvapich2flags"
            ;;
        hmpt-*)
            sed -i "s,PINC       =.*,PINC       = -I${MPI_ROOT}/include -pthread," "$systemopenmpiflags"
            sed -i "s|PLIBS      =.*|PLIBS      = -pthread -Wl,-rpath -Wl,${MPI_ROOT}/lib -Wl,--enable-new-dtags -L${MPI_ROOT}/lib -lmpi|" "$systemopenmpiflags"
            sed -i "s,libDir=.*,libDir=${MPI_ROOT}/lib," "$mpiflags"
            ;;
        openmpi-1.10.4)
            sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=OPENMPI,' "$bashrc"
            ;;
        openmpi-*)
            # No change needed
            ;;
        *)
            echo "Invalid MPI library '$MPILIB'. This is most likely a bug in the script."
            exit 1
            ;;
    esac

    # Set the compiler and flags
    case "$COMPILER" in
        arm-*)
            sed -i 's/^export WM_COMPILER=.*/export WM_COMPILER=Arm/' "$bashrc"

            echo "CC = ${OPT_CC}" >> "$cppflags"
            sed -i '/c++ARCH/ s/$/'" ${OPT_CPPARCH}/" "$cppflags"
            ;;
        cce-*)
            sed -i 's/^export WM_COMPILER=.*/export WM_COMPILER=Clang/' "$bashrc"

            echo "cc = cc" >> "$cflags"
            echo "CC = ${OPT_CC}" >> "$cppflags"
            sed -i '/c++ARCH/ s/$/'" ${OPT_CPPARCH}/" "$cppflags"
            sed -i 's/c++OPT.*/c++OPT      = -O3 -ffast-math -ffp-contract=fast/' "$cppOptflags"

            linkflags="wmake/rules/General/Clang/link-c++"
            sed -i 's/(CC)/(CC) -fuse-ld=bfd/' "$linkflags"
            ;;
        gcc-*)
            sed -i 's,^export WM_COMPILER=.*,export WM_COMPILER=Gcc,' "$bashrc"

            [ -n "${OPT_CC:-}" ] && echo "CC = ${OPT_CC}" >> "$cppflags"
            [ -n "${OPT_CPPARCH:-}" ] && sed -i '/c++ARCH/ s/$/'" ${OPT_CPPARCH}/" "$cppflags"
            [ -n "${OPT_CPPOPT:-}" ] && sed -i "s/^c++OPT      =.*/c++OPT      = ${OPT_CPPOPT}/" "$cppOptflags"
            ;;
        intel-*)
            sed -i 's,^export WM_COMPILER=.*,export WM_COMPILER=Icc,' "$bashrc"
            ;;
        *)
            echo "Invalid compiler '$COMPILER'. This is most likely a bug in the script."
            exit 1
            ;;
    esac
    sed -i '/export WM_COMPILER=.*/a export CRAYPE_LINK_TYPE=dynamic' "$bashrc"
    sed -i '/export export WM_MPLIB=.*/a export WM_NCOMPPROCS='"$OPT_NCOMPPROCS" "$bashrc"

    # Disable -eu because otherwise sourcing bashrc will trigger it
    set +e +u
    source "$bashrc"

    # Additional platform-specific flag changes
    [ "$(type -t override_env)" = "function" ] && override_env

    [ "$restart_build" = yes ] && wclean all
    time ./Allwmake |& tee "build_${ARCH}_${COMPILER}_${MPILIB}.log"

    # Create a test case directory if the files are available (and the directory doesn't exist already)
    popd
    cd "$RUN_DIR"
    testdir="block_DrivAer_small-$ARCH"
    if [ -d "$testdir" ]; then
        echo "Test directory already exists: $testdir"
    elif [ -f OpenFOAM-v1712-block_DrivAer_small.tar.gz ]; then
        mkdir -p "$testdir"
        tar -xf OpenFOAM-v1712-block_DrivAer_small.tar.gz -C "$testdir" --strip-components 1
        sed -i 's/writeCompression compressed;/writeCompression on;/' system/controlDict
    elif [ -d OpenFOAM-v1712-block_DrivAer_small ]; then
        mkdir -p "$testdir"
        cp -r OpenFOAM-v1712-block_DrivAer_small "$testdir"
        sed -i 's/writeCompression compressed;/writeCompression on;/' system/controlDict
    else
        echo "Test case direcotry not available. You will have to obtain and unpack the test case manually before running the benchmark."
    fi

    echo
    echo "Build complete."

elif [ "$action" == "run" ]; then
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Configuration not built: $COMPILER $MPILIB"
        echo "Have you run 'benchmark.sh build $COMPILER $MPILIB'?"
        exit 1
    fi

    if [ "$run_args" == node ]; then
        NODES=1
        jobscript=node.job
    elif [[ "$run_args" == scale-* ]]; then
        export NODES=${run_args#scale-}
        if ! [[ "$NODES" =~ ^[0-9]+$ ]]; then
            echo
            echo "Invalid node count for 'run scale-N' action"
            echo
            exit 1
        fi
        jobscript=scale.job
    else
        echo
        echo "Invalid 'run' argument '$run_args'"
        usage
        exit 1
    fi

    # Some systems use `sh` for job scripts and don't like exported functions
    case "$SYSTEM" in
        catalyst)
            unset -f setup_env
            ;;
    esac

    # Submit job
    cd "$RUN_DIR"
    qsub -l select="${NODES}${PBS_RESOURCES:-}" \
        -o "${PWD}/../OpenFOAM-v2006_${PLATFORM}_${CONFIG}_${run_args}".out \
        -N OpenFOAM_"${run_args}_${CONFIG}" \
        -V \
        "$PLATFORM_DIR/$jobscript"
else
    echo
    echo "Invalid action (use 'build' or 'run')."
    echo
    exit 1
fi

