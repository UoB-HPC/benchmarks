#!/bin/bash

if [ ! -e arch/neutral/omp3/neutral.c ]
then
    git clone https://github.com/UoB-HPC/arch
    cd arch
    git clone https://github.com/UoB-HPC/neutral
    cd neutral
    git checkout 49c946bf54
fi
