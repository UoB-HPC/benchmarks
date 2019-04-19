#!/bin/bash

if [ ! -e SNAP/src/snap_main.f90 ]
then
    git clone https://github.com/lanl/SNAP
    cd SNAP
    git checkout ver1.09-04182019
fi
