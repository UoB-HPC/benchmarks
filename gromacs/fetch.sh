#!/bin/bash

if [ ! -e gromacs-2018.1 ]
then
    wget http://ftp.gromacs.org/pub/gromacs/gromacs-2018.1.tar.gz
    tar xf gromacs-2018.1.tar.gz
fi

if [ ! -e gromacs-benchmarks ]
then
    git clone https://bitbucket.org/pszilard/isambard-bench-pack.git gromacs-benchmarks
fi
