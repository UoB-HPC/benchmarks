#!/bin/bash

DIR="$PWD/arch/neutral"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/neutral_data.c" ]
then
    echo "Directory '$DIR' does not exist or does not contain neutral_data.c"
    exit 1
fi

cd $DIR

module swap craype-{broadwell,mic-knl}
module swap PrgEnv-{cray,intel}
module swap intel intel/18.0.0.128

if ! make -B COMPILER=INTEL \
 CFLAGS_INTEL="-O3 -qopenmp -no-prec-div -std=gnu99 -DINTEL -Wall -xMIC-AVX512"
then
    echo "Build failed"
    exit 1
fi

mv neutral.omp3 neutral.omp3.knl
