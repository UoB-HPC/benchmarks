#!/bin/bash

if [ ! -e neutral_ocl/main.c ]
then
    git clone git@github.com:UoB-HPC/neutral_ocl.git
    cd neutral_ocl
    git checkout 1900dce7da 
fi
