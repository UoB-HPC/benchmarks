This repository contains scripts for running various benchmarks in a reproducible manner.
This is primarily for benchmarking ThunderX2 in Isambard, and other systems that we typically compare against.

The scripts in each directory roughly adhere to the following usage pattern:

    # If this script is present, use it to get the sources and test data for the benchmark.
    ./fetch.sh
    
    # If this script is present, use it to build the benchmark for the target platform.
    ./build-<cpu>-<system>.sh
    
    # This script should always be present, and actually runs the benchmark.
    # On most systems, this will probably be a job script, so use `qsub/sbatch` etc.
    qsub run-<cpu>-<system>.sh
