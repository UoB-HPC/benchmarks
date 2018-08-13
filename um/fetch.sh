#!/bin/bash

if [ ! -r fcm/bin/fcm ]
then
    git clone https://github.com/metomi/fcm
fi

if [ ! -r um-amip/common/data/STASHmaster_A ]
then
    mkdir -p um-amip
    if [ ! -r vn10_8_benchmark_r2_arm.tar.gz ]
    then
        echo
        echo "Download AMIP benchmark into current directory."
        echo
        echo "Tested with 'vn10_8_benchmark_r2_arm.tar.gz'"
        echo "MD5: 6174fbeddd20982a62e67d192f26febb"
        echo
        exit 1
    fi

    tar xf vn10_8_benchmark_r2_arm.tar.gz -C um-amip
fi
