#!/bin/bash

if [ ! -r fcm/bin/fcm ]
then
    git clone https://github.com/metomi/fcm
fi

if [ ! -r amip/common/data/STASHmaster_A ]
then
    mkdir -p amip
    echo
    echo "Unpack AMIP benchmark into amip/"
    echo "e.g. tar xf vn10_8_benchmark_r2_arm.tar.gz -C amip"
    echo
    echo "Tested with 'vn10_8_benchmark_r2_arm.tar.gz'"
    echo "MD5: 6174fbeddd20982a62e67d192f26febb"
    echo
else
    echo "AMIP benchmark files already present."
fi
