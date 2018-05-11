#!/bin/bash

module load craype-x86-skylake
#module swap cce cce/8.7.0
module load cray-netcdf

cd NEMO_benchmarks/NEMOGCM/CONFIG
if ! ./makenemo -r GYRE_PISCES_ARM_test -m "XC40_METO" -n "SKL" del_key "key_iomput"
then
    echo "Building NEMO failed"
    exit 1
fi
