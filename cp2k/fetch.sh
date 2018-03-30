#!/bin/bash

if [ -e cp2k-5.1 ]
then
    echo "cp2k-5.1 already exists"
    exit 1
fi

wget https://netix.dl.sourceforge.net/project/cp2k/cp2k-5.1.tar.bz2
tar xf cp2k-5.1.tar.bz2

wget https://github.com/hfp/libxsmm/archive/1.9.tar.gz
tar xf 1.9.tar.gz
