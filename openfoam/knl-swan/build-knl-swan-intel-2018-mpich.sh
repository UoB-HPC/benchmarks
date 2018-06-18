#!/bin/bash

set -eu
set -o pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

basedir="$PWD/OpenFOAM-v1712-KNL-Intel-18-cray-mpich-7.7.0"
[ $# -gt 0 ] && basedir="$1"

if [ -d "$basedir" ]; then
    echo "$0: Installation direcotry already exists: $basedir" >&2
    echo "$0: Stop." >&2
    exit 1
fi

tgz_of="OpenFOAM-v1712.tgz"
tgz_tp="ThirdParty-v1712.tgz"

if [ ! -f "$tgz_of" ] || [ ! -f "$tgz_tp" ]; then
    echo "$0: Missing source code archives. Have you run fetch.sh?" >&2
    echo "$0: Stop." >&2
    exit 2
fi

echo "Unzipping $tgz_of..."
tar -xf "$tgz_of" -C "$basedir"
echo "Unzipping $tgz_tp..."
tar -xf "$tgz_tp" -C "$basedir"

# Copy modified build files
#arch=$(basename "$0" | sed -e 's/^build-//' -e 's/\..*$//')
#[ -d "$arch" ] && cp -r "$arch"/* "$basedir"
cp -r "$script_dir"/../build-parts/common-intel-mpich/* "$basedir"

pushd "$basedir/OpenFOAM-v1712"

bashrc="etc/bashrc"
cflags="wmake/rules/linux64IccKNL/c"
cppflags="wmake/rules/linux64IccKNL/c++"
cppOptflags="wmake/rules/linux64IccKNL/c++Opt"

if [ ! -f "$bashrc" ]; then
    echo "$0: File does not exist: $PWD/$bashrc" >&2
    echo "$0: Stop." >&2
    exit 2
fi

# Use the Intel Compiler
current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
module swap PrgEnv-$current_env PrgEnv-intel
module swap intel intel/18.0.0.128

# Set the installtion directory path, the compiler to Intel KNL, and the MPI library to cray-mpich
sed -i 's,^FOAM_INST_DIR=.*,FOAM_INST_DIR='"$PWD," "$bashrc"
sed -i 's,^export WM_COMPILER=.*,export WM_COMPILER=IccKNL,' "$bashrc"
sed -i 's,^export WM_MPLIB=.*,export WM_MPLIB=CRAY-MPICH,' "$bashrc"

# Set the compiler flags
sed -i 's/-m64//' "$cflags"
sed -i 's/-m64//' "$cppflags"
sed -i '/^CC          =/ s/$/ -qopenmp/' "$cppflags"
cat >>"$cppOptflags" <<EOF
# Suppress some warnings for flex++ and CGAL
c++LESSWARN = -Wno-old-style-cast -Wno-unused-local-typedefs -Wno-array-bounds -fpermissive
EOF

set +e +u
source "$bashrc"

# Additional flag changes: enable parallel compilation and remove `m64`, which Cray GCC doesn't like
export WM_NCOMPPROCS=8
export WM_CFLAGS='-fPIC' WM_CXXFLAGS='-fPIC -std=c++11' WM_LDFLAGS=''

time ./Allwmake |& tee build.log

# If the build fails with 'too many open files' error, try again with a single thread
if [ "$(grep -c 'open files' build.log)" -gt 0 ]; then
    echo "Got 'Too many open files errors. Retrying build with a single parallel job..."
    export WM_NCOMPPROCS=1
    time ./Allwmake |& tee build_1proc.log
fi

# Create a test case directory if the files are available (and the directory doesn't exist already)
popd
testdir="run/block_DrivAer_small-knl"
if [ -d "$testdir" ]; then
    echo "Test directory already exists: $testdir"
elif [ -f OpenFOAM-v1712-block_DrivAer_small.tar.gz ]; then
    mkdir -p "$testdir"
    tar -xf OpenFOAM-v1712-block_DrivAer_small.tar.gz -C "$testdir" --strip-components 1
elif [ -d OpenFOAM-v1712-block_DrivAer_small ]; then
    mkdir -p "$testdir"
    cp -r OpenFOAM-v1712-block_DrivAer_small "$testdir"
else
    echo "$0: Test case direcotry not available. Have you run fetch.sh?" >&2
    exit 4
fi

echo "Done."

