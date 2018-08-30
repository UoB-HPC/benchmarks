# UoB HPC Benchmarks

This repository contains scripts for running various benchmarks in a reproducible manner.
This is primarily for benchmarking ThunderX2 in Isambard, and other systems that we typically compare against.

## Structure

Each top-level directory contains scripts for a (mini-)application.
Inside it, there is a directory for each target platform, which contains the main benchmark script for the application-platform combination.
Depending on the application and platform, there may be additional files required for building and running the benchmark, which are also included in the above directories.

## Usage

The following section assumes that the root of this repository is available at `$REPO`.

To run a benchmark with the default settings:

1. Change to a directory where the benchmark will be installed. The source code for the benchmark will be downloaded here, and some applications are built into a separate new directory.
```bash
mkdir benchmarks && cd benchmarks
```

2. Run the `build` action of your chosen benchmark and platform to compile the application. If the application sources are not already available locally, they will be downloaded automatically; you do not need to run `fetch.sh` manually.
```bash
# Example for CloverLeaf on TX2
$REPO/cloverleaf/tx2-foxconn/benchmark.sh build
```

3. Use the `run` action to start the benchmark. On systems with a queue, a job will be submitted. Otherwise, the benchmark will start running on the current node.
```bash
# Example for CloverLeaf on TX2, assuming you have previously run 'build'
$REPO/cloverleaf/tx2-foxconn/benchmark.sh run
```

### Using custom settings

Some applications support various build-time or run-time options. In particular, most applications support more than one compiler choice, and some support various library options, e.g. for MPI or maths. To see all the available options, run `benchmark.sh` without any action:

```bash
# Example for OpenFOAM on TX2
$REPO/openfoam/tx2-foxconn/benchmark.sh
```

Once you have chosen your settings, build and run the benchmark _using the same parameters_. For example, OpenFOAM on TX2 uses GCC 7.2.0 and OpenMPI 3.1.0 by default. To use the Arm compiler and the bundled (_ThirdParty_) version of OpenMPI instead:

```bash
$REPO/openfoam/tx2-foxconn/benchmark.sh build arm-18.3 openmpi-1.10.4
$REPO/openfoam/tx2-foxconn/benchmark.sh run arm-18.3 openmpi-1.10.4
```

## Platforms

**tx2-foxconn:**
Early-access Cavium ThunderX2 systems available as part of the Isambard project.
Dual-socket Cavium ThunderX2 (B0) 32-core @ 2.2 GHz, with 256 GB of DDR4-2666 memory (with memory clock running at 2200 MHz).

**bdw-swan:**
Cray Marketing Partner Network system.
Dual-socket Intel Xeon E5-2699 v4 (Broadwell) 22-core @ 2.2 GHz, with 128 GB of DDR4-2400 memory.

**skl-swan:**
Cray Marketing Partner Network system.
Dual-socket Intel Xeon Platinum 8176 (Skylake) 28-core @ 2.1 GHz, with 192 GB of DDR4-2666 memory.

**skl-horizon:**
Internal system provided by Cray.
Dual-socket Intel Xeon Gold 6148 (Skylake) 20-core @ 2.4 GHz, with 192 GB of DDR4-2666 memory.
