#!/bin/bash

if [ ! -r fcm/bin/fcm ]
then
    git clone https://github.com/metomi/fcm
fi

if [ ! -r amip/amip4x8/data/vertlevs_L85_50t_35s_85km ]
then
    mkdir -p amip
    echo "Unpack amip benchmark into amip/"
fi
