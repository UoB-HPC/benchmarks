#!/bin/bash

if [ ! -e CloverLeaf_ref/clover.f90 ]
then
    git clone https://github.com/UK-MAC/CloverLeaf_ref
    cd CloverLeaf_ref
    git checkout v1.3
fi
