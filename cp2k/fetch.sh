#!/bin/bash

if [ ! -e cp2k-5.1 ]
then
    wget https://github.com/cp2k/cp2k/releases/download/v5.1.0/cp2k-5.1.tar.bz2
    tar xf cp2k-5.1.tar.bz2

    wget https://github.com/hfp/libxsmm/archive/1.9.tar.gz
    tar xf 1.9.tar.gz
fi
