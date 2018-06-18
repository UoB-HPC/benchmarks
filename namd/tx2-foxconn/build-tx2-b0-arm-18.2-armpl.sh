#!/bin/bash

set -eu
set -o pipefail

namd_dir="$PWD/NAMD_2.12_Source"
charm_dir="$PWD/charm-v6.8.2"
install_dir="${1:-$PWD/NAMD-2.12-TX2-armclang-18.2-charm-6.8.2-armpl-18.2}"

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

# Use the Arm HPC Compiler
module purge
module load arm/hpc-compiler/18.2 arm/perf-libs/18.2/arm-18.2

echo "Building Charm++..."

charm_install_dir="$install_dir/charm682"
mkdir -p "$charm_install_dir"

pushd "$charm_dir"

charmarch="multicore-linux-aarch64"
./build charm++ "$charmarch" --with-production --destination="$charm_install_dir/$charmarch" -j16

echo
echo "Building NAMD..."

cd "$namd_dir"

namd_target="Linux-ARM64-armclang"

sed -i '/CHARMBASE/d' "arch/$namd_target.arch"
echo "CHARMBASE=$charm_install_dir" >> "arch/$namd_target.arch"
#sed -i 's,^FFTDIR=.*,FFTDIR='"/opt/cray/pe/fftw/$CRAY_FFTW_VERSION/arm_thunderx2," "arch/${namd_target%-armclang}.fftw3"
sed -i 's,^FFTDIR=.*,FFTDIR='"$ARMPL_DIR," "arch/${namd_target%-armclang}.fftw3"
sed -i '/FFTLIB/ s/-lfftw3f/-larmpl/' "arch/${namd_target%-armclang}.fftw3"

rm -rf "$namd_target"
./config "$namd_target" --with-fftw3 --without-tcl --charm-arch "$charmarch"
cd "$namd_target"
make -j16
cp charmrun namd2 "$install_dir"

echo
echo "Done."

