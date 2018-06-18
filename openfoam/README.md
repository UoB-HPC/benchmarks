# OpenFOAM

These scripts build and run [OpenFOAM v1712](https://www.openfoam.com/download/).

## Build notes

Due to the way OpenFOAM is "installed", we create a separate installation directory for each platform. Thus, `fetch.sh` will only download the packages, which will be unarchived in `build-*.sh`.

We use the GNU compiler on x86 and ARM because it has the best performance. We use the Intel compiler on KNL because we _assume_ it won't do worse than GNU.

We use the same build for both Broadwell and Skylake, as we cannot enable the `-march=core-avx*` options. Doing so will cause the test case to diverge...

### Build issues

As of 07-Apr-2018, we get "Too many open files" errors when building with multiple threads on Swan. Because fully building with a single thread takes a _very log_ time, we try the following workaround:

1. run a parallel build.
2. If this fails, we try again with a single thread.

While this seems to work for now, remember that it is essentially a hack, and thus it may not work next time. If it does not, you will need to manually load the required modules and `source` OpenFOAM's `etc/bashrc`, then restart the build manually:

```bash
cd OpenFOAM-<build>/OpenFOAM-v1712
export WM_NCOMPPROCS=1
./Allwmake
```

Note that builds with the Intel compiler don't build Boost succesfully, but this should not cause any problems.


## Run notes

We use the `DrivAer` test case from the 2nd Isambard Hackathon. This isn't available online, so the script only copies it if it is running on Isambard. Otherwise, you need to manually get it from `isambard:/lustre/projects/bristol/OpenFOAM/test-cases/OpenFOAM-v1712-block_DrivAer_small.tar.gz`.

Because of how OpenFOAM decomposes test cases, we need to set up a separate directory for each platform. `build.sh` attempts to do this automatically at the end of the build, as long as the case has been downloaded before. If it hasn't, you will need to set it up manually in `run/block_DrivAer_small-<arch>`.

HyperThreading results are:

* Marginally (~3%) faster on TX2 with GCC and 4 processes/core
    - But 2 processes/core is fastest with armclang
* Marginally (~5%) slower on BDW and SKL
* ~20% faster on KNL with 2 processes/core
    - But 4 processes/core uses too much memory for flat mode, and cache mode is 10% slower vs 2 processes/core.

