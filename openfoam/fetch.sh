#!/bin/bash

set -eu
set -o pipefail

# basedir="OpenFOAM-v1712"
tgz_of="OpenFOAM-v1712.tgz"
tgz_tp="ThirdParty-v1712.tgz"

# Installation
# if [ -d "$basedir" ]; then
#     echo "$0: OpenFOAM installation directory already exists: $basedir" >&2
# else

echo "Downloading OpenFOAM..."
# mkdir "$basedir"

# OpenFOAM
if [ ! -f "$tgz_of" ]; then
    wget https://sourceforge.net/projects/openfoamplus/files/v1712/OpenFOAM-v1712.tgz
else
    echo "$0: File already exists: $tgz_of" >&2
    echo "$0: Skipping download." >&2
fi

h=$(md5sum "$tgz_of" | awk '{print $1}')
if [[ "$h" != "6ad92df051f4d52c7d0ec34f4b8eb3bc" ]]; then
    echo "$0: Checksum does NOT match for: $tgz_of" >&2
fi

# tar -xf "$tgz_of" -C "$basedir"

# ThirdParty
if [ ! -f "$tgz_tp" ]; then
    wget https://sourceforge.net/projects/openfoamplus/files/v1712/ThirdParty-v1712.tgz
else
    echo "$0: File already exists: $tgz_tp" >&2
    echo "$0: Skipping download." >&2
fi

h=$(md5sum "$tgz_tp" | awk '{print $1}')
if [[ "$h" != "c5662a79d4e997472a78b7cc6da98edd" ]]; then
    echo "$0: Checksum does NOT match for: $tgz_tp" >&2
fi

    # tar -xf "$tgz_tp" -C "$basedir"
# fi

echo

# Test case
[ ! -d run ] && mkdir run
cd run

if [ ! -f /lustre/projects/bristol/OpenFOAM/test-cases/OpenFOAM-v1712-block_DrivAer_small.tar.gz ]; then
    echo "Please copy over the test case manually."
    echo "This is available at isambard:/lustre/projects/bristol/OpenFOAM/test-cases/OpenFOAM-v1712-block_DrivAer_small.tar.gz"
elif [ -d  block_DrivAer_small ]; then
    echo "$0: Test case directory already exists: $0" >&2
else
    echo "Unzipping test case..."
    tar xf /lustre/projects/bristol/OpenFOAM/test-cases/OpenFOAM-v1712-block_DrivAer_small.tar.gz
    echo "You should create a separate copy for each test platform: cp block_DrivAer_small block_DrivAer_small-<platform>"
    # for a in tx2 bdw skl knl; do
    #     rundir="block_DrivAer_small-$a"
    #     if [ -d "$rundir" ]; then
    #         echo "$0: Test case directory already exists: $0" >&2
    #     else
    #         echo "$0: Unzipping test case for $a..." >&2
    #         tar xf /lustre/projects/bristol/OpenFOAM/test-cases/OpenFOAM-v1712-block_DrivAer_small.tar.gz
    #         mv block_DrivAer_small "$rundir"
    #     fi
    # done
fi

echo "Done."

