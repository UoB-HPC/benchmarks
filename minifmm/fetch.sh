#!/bin/bash

if [ ! -e minifmm/main.cc ]
then
    git clone https://github.com/UoB-HPC/minifmm.git
    cd minifmm
    git checkout v0.2
fi
