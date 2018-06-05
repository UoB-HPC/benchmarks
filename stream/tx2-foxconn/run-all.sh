#!/bin/bash

VERSIONS="gcc-8.1 arm-18.3 cce-8.7"

for V in $VERSIONS
do
    echo -n "$V: "
    ./run-$V.sh | grep Triad | awk '{print $2}'
done
