#!/bin/bash

if [ ! -r fcm/bin/fcm ]
then
    git clone https://github.com/metomi/fcm
fi

if [ ! -r amip/common/data/STASHmaster_A ]
then
    mkdir -p amip
    echo "Unpack amip benchmark into amip/"
fi
