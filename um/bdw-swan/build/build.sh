#!/bin/bash --login

set -e

module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

export basepath=$(readlink -f "$PWD/../../amip/")
echo "basepath = $basepath"

export BUILD_DIR=$PWD

export DATE=$(date)

fcm make -f drhook.cfg -v --new -j 88
fcm make -f gcom.cfg -v --new -j 88
fcm make -v --new -j 88
