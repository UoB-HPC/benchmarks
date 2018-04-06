#!/bin/bash --login

set -e

rm -rf build
mkdir build
cd build

module swap craype-{broadwell,x86-skylake}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

export basepath=$(readlink -f "$PWD/../../amip/")
echo "basepath = $basepath"

export BUILD_DIR=$PWD

export DATE=$(date)

fcm make -f ../drhook.cfg -v --new -j 112
fcm make -f ../gcom.cfg -v --new -j 112
fcm make -f ../fcm-make.cfg -v --new -j 112
