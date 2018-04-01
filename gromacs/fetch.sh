#!/bin/bash

if [ -e gromacs-2018.1 ]
then
    echo "gromacs-2018.1 already exists"
    exit 1
fi

wget http://ftp.gromacs.org/pub/gromacs/gromacs-2018.1.tar.gz
tar xf gromacs-2018.1.tar.gz

git clone https://bitbucket.org/pszilard/isambard-bench-pack.git benchmarks
