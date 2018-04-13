#!/bin/bash

module load cray-netcdf

cd NEMO_benchmarks/NEMOGCM/CONFIG
if ! ./makenemo -r GYRE_PISCES_ARM_test -m "XC40_METO" -n "BDW" del_key "key_iomput"
then
    echo "Building NEMO failed"
    exit 1
fi
