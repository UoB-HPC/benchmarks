# UoB HPC Benchmarks

This repository contains scripts for running various benchmarks in a reproducible manner.
This is primarily for benchmarking ThunderX2 in Isambard, and other systems that we typically compare against.

## Structure

Each top-level directory contains scripts for a (mini-)application.
Inside it, there is a `common.sh` script which drives the compilation of the benchmark code and submits benchmarking jobs to the queue.
There is a sub-directory for each target platform, which contains a `benchmark.sh` script describing platform-specific details about how the benchmark will be compiled and the job submissions scripts.
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
$REPO/cloverleaf/tx2-isambard/benchmark.sh build
```

3. Use the `run` action to start the benchmark, specifying the scale (number of nodes), which will submit a job to the queue.
```bash
# Example for CloverLeaf on TX2, running on 64 nodes (assuming you have previously run 'build')
$REPO/cloverleaf/tx2-isambard/benchmark.sh run scale-64
```

### Using custom settings

Some applications support various build-time or run-time options. In particular, most applications support more than one compiler choice, and some support various library options, e.g. for MPI or maths. To see all the available options, run `benchmark.sh` without any action:

```bash
# Example for GROMACS on TX2
$REPO/gromacs/tx2-isambard/benchmark.sh
```

Once you have chosen your settings, build and run the benchmark _using the same parameters_. For example, GROMACS on Isambard uses GCC 8.2.0 and FFTW 3.3.8 by default. To use the Arm compiler and the Arm performance libraries instead:

```bash
$REPO/gromacs/tx2-isambard/benchmark.sh build arm-19.0 armpl-19.0
$REPO/gromacs/tx2-isambard/benchmark.sh run scale-64 arm-19.0 armpl-19.0
```

## Platforms

**tx2-isambard:**
Isambard Cray XC50 system.
Dual-socket Marvell ThunderX2 32-core @ 2.1 GHz (2.5 GHz boost), with 256 GB of DDR4-2666 memory.

**bdw-swan:**
Cray Marketing Partner Network system.
Dual-socket Intel Xeon E5-2699 v4 (Broadwell) 22-core @ 2.2 GHz, with 128 GB of DDR4-2400 memory.

**skl-swan:**
Cray Marketing Partner Network system.
Dual-socket Intel Xeon Platinum 8176 (Skylake) 28-core @ 2.1 GHz, with 192 GB of DDR4-2666 memory.

**skl-horizon:**
Internal system provided by Cray.
Dual-socket Intel Xeon Gold 6148 (Skylake) 20-core @ 2.4 GHz, with 192 GB of DDR4-2666 memory.
