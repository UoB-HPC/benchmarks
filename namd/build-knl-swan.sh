#!/bin/bash

set -eu
set -o pipefail

namd_dir="$PWD/NAMD_2.12_Source"
charm_dir="$PWD/charm-v6.8.2"
install_dir="${1:-$PWD/NAMD-2.12-KNL-Intel-18-charm-6.8.2-cray-fftw-3.3.6.3}"

if [ ! -d "$namd_dir" ] || [ ! -d "$charm_dir" ]; then
    echo "NAMD and Charm++ sources not present. Have you run fetch.sh?" >&2
    echo "Stop." >&2
    exit 1
fi

if [ -d "$install_dir" ]; then
    echo "Installation directory already exists: $install_dir." >&2
    echo "Stop." >&2
    exit 2
fi

echo "Installing into: $install_dir"

# Use the Intel Compiler
current_env=$( module li 2>&1 | grep PrgEnv | sed -r 's/[^-]*-([a-z]+).*/\1/')
module swap "PrgEnv-$current_env" PrgEnv-intel
module swap intel intel/18.0.0.128
module swap "craype-$CRAY_CPU_TARGET" craype-mic-knl
module load cray-fftw/3.3.6.3
module load craype-hugepages8M

echo "Building Charm++..."

charm_install_dir="$install_dir/charm682"
mkdir -p "$charm_install_dir"

pushd "$charm_dir"

charmarch="multicore-linux64"
#charmarch="gni-crayxc"
./build charm++ "$charmarch" iccstatic --with-production --destination="$charm_install_dir/$charmarch" -j8

echo
echo "Building NAMD..."

cd "$namd_dir"

namd_target="Linux-KNL-icc"
sed -i 's,^CHARMARCH =.*,CHARMARCH = '"$charmarch," "arch/$namd_target.arch"
sed -i '/CHARMBASE/d' "arch/$namd_target.arch"
echo "CHARMBASE=$charm_install_dir" >> "arch/$namd_target.arch"

fftw3_dir="$(readlink -f $FFTW_DIR/..)"
sed -i 's,^FFTDIR=.*,FFTDIR='"$fftw3_dir," arch/Linux-KNL.fftw3

rm -rf "$namd_target"
./config "$namd_target" --with-fftw3 --without-tcl --charm-arch "$charmarch"
cd "$namd_target"
make -j8
cp charmrun namd2 "$install_dir"

echo
echo "Done."

