#!/bin/bash

if [ -e OpenSBLI ]
then
    echo "OpenSBLI already exists"
    exit 1
fi

wget http://www.archer.ac.uk/community/benchmarks/archer/OpenSBLI_ARCHER_bench.zip
unzip OpenSBLI_ARCHER_bench.zip
echo "ss 256 500 1 False" >OpenSBLI/Benchmark/input

# Fix a buffer overrun bug in the benchmark code
sed -i 's/char type_of_simulation\[2\], HDF5op\[4\];/char type_of_simulation[3], HDF5op[6];/' OpenSBLI/Benchmark/OpenSBLI_ops.cpp
