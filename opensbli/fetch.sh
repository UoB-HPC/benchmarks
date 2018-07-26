#!/bin/bash

if [ ! -e OpenSBLI/Benchmark/OpenSBLI_ops.cpp ]
then
    wget http://www.archer.ac.uk/community/benchmarks/archer/OpenSBLI_ARCHER_bench.zip
    unzip OpenSBLI_ARCHER_bench.zip

    # Fix a buffer overrun bug in the benchmark code
    sed -i 's/char type_of_simulation\[2\], HDF5op\[4\];/char type_of_simulation[3], HDF5op[6];/' OpenSBLI/Benchmark/OpenSBLI_ops.cpp
fi
