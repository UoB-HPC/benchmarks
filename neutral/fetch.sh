#!/bin/bash

if [ ! -e arch/neutral/omp3/neutral.c ]
then
    git clone https://github.com/UoB-HPC/arch
    cd arch
    git checkout f19d9325d9

    git clone https://github.com/UoB-HPC/neutral
    cd neutral
    git checkout d983598634
fi
