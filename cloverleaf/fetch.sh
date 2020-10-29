#!/bin/bash

if [ ! -e CloverLeaf_ref/clover.f90 ]
then
    git clone https://github.com/UK-MAC/CloverLeaf_ref
    cd CloverLeaf_ref
    git checkout 612c2da46cffe26941e5a06492215bdef2c3f971
fi
