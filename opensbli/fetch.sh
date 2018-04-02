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
PIP=pip
if ! hash $PIP
then
    PIP=$HOME/.local/bin/pip
    if ! hash $PIP
    then
        if ! easy_install --user pip
        then
            echo "Failed to find or install pip"
            exit 1
        fi
    fi
fi
$PIP install --user -r requirements.txt
