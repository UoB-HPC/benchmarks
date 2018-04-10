#!/bin/bash

export PATH=$PWD/fcm/bin:$PATH

module swap cce cce/8.6.4

cd tx2-b0
if ! ./build.sh
then
    echo "Building failed"
    exit 1
fi
