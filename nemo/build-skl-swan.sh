#!/bin/bash

module swap craype-{broadwell,x86-skylake}
module load cray-netcdf

cd NEMOGCM/CONFIG
if ! ./makenemo -r GYRE_PISCES -m "XC40_METO" -n "SKL" del_key "key_iomput"
then
    echo "Building NEMO failed"
    exit 1
fi
