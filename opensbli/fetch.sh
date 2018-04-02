#!/bin/bash

if [ -e OpenSBLI ]
then
    echo "OpenSBLI already exists"
    exit 1
fi

wget http://www.archer.ac.uk/community/benchmarks/archer/OpenSBLI_ARCHER_bench.zip
unzip OpenSBLI_ARCHER_bench.zip
echo "ss 256 500 1 False" >OpenSBLI/Benchmark/input

# Get other dependencies.
easy_install --user pip
$HOME/.local/bin/pip install --user -r requirements.txt
