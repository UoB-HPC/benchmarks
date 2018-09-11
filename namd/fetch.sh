#!/bin/bash

set -eu
set -o pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tgz_charm="charm-6.8.2.tar.gz"
tgz_namd="NAMD_2.12_Source.tar.gz"
tgz_stmv="stmv.tar.gz"

echo "Downloading Charm++..."
if [ ! -f "$tgz_charm" ]; then
    wget https://charm.cs.illinois.edu/distrib/charm-6.8.2.tar.gz
else
    echo "File already exists: $tgz_charm" >&2
    echo "Skipping download." >&2
fi

h=$(sha256sum "$tgz_charm" | awk '{print $1}')
if [[ "$h" != "08e6001b0e9cd00ebde179f76098767149bf7e454f29028fb9a8bfb55778698e" ]]; then
    echo "Checksum does NOT match for: $tgz_charm" >&2
fi

echo "Unpacking Charm++..."
tar xf "$tgz_charm"

echo "Downloading NAMD..."
if [ ! -f "$tgz_namd" ]; then
    wget --no-check-certificate https://www.ks.uiuc.edu/Research/namd/2.12/download/832164/NAMD_2.12_Source.tar.gz
else
    echo "File already exists: $tgz_namd" >&2
    echo "Skipping download." >&2
fi

h=$(sha256sum "$tgz_namd" | awk '{print $1}')
if [[ "$h" != "436d11e4ff78136c7463d448d2eee92509a39b4c03cab8d07176bb20ddcb675a" ]]; then
    echo "Checksum does NOT match for: $tgz_namd" >&2
fi

echo "Unpacking NAMD..."
tar xf "$tgz_namd"

echo "Copying modified files..."
cp -r "$script_dir"/common/* ./

echo "Downloading STMV test case..."
if [ ! -f "$tgz_stmv" ]; then
    wget --no-check-certificate https://www.ks.uiuc.edu/Research/namd/utilities/stmv.tar.gz
else
    echo "File already exists: $tgz_stmv" >&2
    echo "Skipping download." >&2
fi

h=$(sha256sum "$tgz_stmv" | awk '{print $1}')
if [[ "$h" != "2ef8beaa22046f2bf4ddc85bb8141391a27041302f101f5302f937d04104ccdd" ]]; then
    echo "Checksum does NOT match for: $tgz_stmv" >&2
fi

echo "Unpacking STMV test case..."
tar xf "$tgz_stmv"
sed -i 's,^outputName.*,outputName          '"$PWD/stmv/out," stmv/stmv.namd
sed -i 's/;#.*//' stmv/stmv.namd

cp stmv/stmv.namd stmv/stmv.armpl.namd
cat >>stmv/stmv.armpl.namd <<EOF

FFTWEstimate yes
FFTWUseWisdom no
EOF

echo "Done."

