# NAMD

## Build notes

We use compilers as follows:

- TX2: Armclang is 20% faster than GNU!
- BDW: GNU compiler is 6% faster than Intel
- SKL: Intel compiler gives 5% better performance than GNU.
- KNL: Intel compiler, because the KNL version uses Intel intrinsics

On TX2, we use `cray-fftw`, since armpl produces invalid results. When switching back to armpl for further test, note the following changes from [the Arm NAMD build guide](https://developer.arm.com/products/software-development-tools/hpc/resources/porting-and-tuning/building-namd-with-arm-compiler):

- In `NAMD_2.12_Source/arch/Linux-ARM64.fftw3`, set `FFTLIB` to use `-larmpl -lflang -lflangrti` instead of `-lfftw3f`
- When running the `STMV` benchmark, use the _modified_ `stmv.armpl.namd` input file

On Cray, we build by invoking the compiler directly (as opposed to using Cray's wrappers) because that seems the most straight-forward approach. There are some [Cray-specific targets](http://docs.cray.com/books/S-2802-10//S-2802-10.pdf) that can use the wrappers with all the compilers, but this produce SMP-enabled Charm++ builds, which---according to [the Charm++ docs](https://charm.cs.illinois.edu/manuals/html/charm++/manual-1p.html#sec:run)---dedicate an entire core to communication. Since we only run single-node, it is probably best to use the (non-MPI) `multicore` target.

Note that the current version of NAMD (v2.12) does _not_ have a `CRAY-XC-cce` target, as the document above implies. The only `CRAY-XC-*` targets are for the Intel compiler. Attempting to use manually created arch files for CCE results in several function declaration errors.

Charm++ is not built with any optimisation flags, but this does not seem to impact NAMD performance. When the NAMD build process uses the Charm compiler, it will add its own optimisations flags.

## Run notes

We use the `STMV` benchmark, which can be downloaded form the [NAMD Utilities page](https://www-s.ks.uiuc.edu/Research/namd/utilities/). According to that page, this benchmark is "useful for demonstrating scaling to thousands of processors". It is also (likely) the one that was used for the 2nd Isambard Hackathon.

Another popular benchmark is `ApoA1`, which is also available to download from the same page, but it is a much smaller test case, and so results are not as convincing. For reference, `STMV` takes about 100 seconds on 44 BDW cores, whereas `ApoA1` takes aroud 10.

Running with more than 1 thread/core produces slightly (10-15%) better results on both TX2 and x86. On KNL, 2 threads/core is 20% better than 1, but 4 threads/core is only 17% better than 1.

On TX2:

- If running an armpl build, don't forget to used the modified input file, `stmv.armpl.namd`
- If using fewer than the maximum number of threads, you need to set the core binding manually with `+pemap`, as per [the Charm++ docs](https://charm.cs.illinois.edu/manuals/html/charm++/manual-1p.html#sec:run):
     - For 64 (out of 256) threads: `+p64 +pemap 0-31,128-159`
     - For 128 (out of 256) threads: `+p128 +pemap 0-63,128-191`

## More scripts

These scripts are not useful for the main benchmark runs. However, they were used at some point and led to slower results, and they may be useful again in the future.

Note that the CCE scripts do not currently produce a complete build due to compiler errors (which seem unrelated to the build parameters).

