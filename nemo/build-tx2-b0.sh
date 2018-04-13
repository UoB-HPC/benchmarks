#!/bin/bash

cp arch-tx2-b0.fcm NEMO_benchmarks/NEMOGCM/ARCH/

export NETCDF_DIR=/lustre/projects/cray/lanton/cce_8.7nightly-180214
export HDF5_DIR=$NETCDF_DIR

cd NEMO_benchmarks/NEMOGCM/CONFIG

if ! ./makenemo -r GYRE_PISCES_ARM_test -m "tx2-b0" -n "TX2" -j 1 del_key "key_iomput"
then
    echo "Building NEMO failed"
    exit 1
fi
