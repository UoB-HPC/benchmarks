#!/bin/bash --login

set -e

export basepath=$(readlink -f "$PWD/../amip")
echo "basepath = $basepath"

export DATE=$(date)

rm -rf build
mkdir build
cd build

export BUILD_DIR=$PWD
export LIBDIR_ROOT=$PWD/shumlib
export LIBDIR_OUT=$PWD/shumlib
export DIR_ROOT=$basepath/shumlib

mkdir -p ${LIBDIR_OUT}
mkdir -p ${DIR_ROOT}/shum_thread_utils/src
mkdir -p ${DIR_ROOT}/shum_latlon_eq_grids/src
mkdir -p ${DIR_ROOT}/shum_data_conv/src
mkdir -p ${DIR_ROOT}/shum_byteswap/src
mkdir -p ${DIR_ROOT}/fruit

echo -e "clean:" > ${DIR_ROOT}/shum_thread_utils/src/Makefile
echo -e "clean:" > ${DIR_ROOT}/shum_latlon_eq_grids/src/Makefile
echo -e "clean:" > ${DIR_ROOT}/shum_data_conv/src/Makefile
echo -e "clean:" > ${DIR_ROOT}/shum_byteswap/src/Makefile
echo -e "clean:" > ${DIR_ROOT}/fruit/Makefile
echo -e "clean:" > ${DIR_ROOT}/fruit/Makefile-driver

make -f $PWD/../shumlib.mk clean
make -f $PWD/../shumlib.mk shum_wgdos_packing shum_string_conv

fcm make -f ../drhook.cfg -v --new -j 112
fcm make -f ../gcom.cfg -v --new -j 112
fcm make -f ../fcm-make.cfg -v --new -j 112
