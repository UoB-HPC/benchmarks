# NAMD

## Build notes

We use compilers as follows:

- TX2: ???
- BDW: GNU compiler is 6% faster than Intel
- SKL: Intel compiler gives 5% better performance than GNU.
- KNL: ???

On Cray, we build by invoking the compiler directly (as opposed to using Cray's wrappers) because that seems the most straight-forward approach. There are some [Cray-specific targets](http://docs.cray.com/books/S-2802-10//S-2802-10.pdf) that can use the wrappers with all the compilers, but this produce SMP-enabled Charm++ builds, which---according to [the Charm++ docs](https://charm.cs.illinois.edu/manuals/html/charm++/manual-1p.html#sec:run)---dedicate an entire core to communication. Since we only run single-node, it is probably best to use the (non-MPI) `multicore` target.

Note that the current version of NAMD (v2.12) does _not_ have a `CRAY-XC-cce` target, as the document above implies. The only `CRAY-XC-*` targets are for the Intel compiler. Attempting to use manually created arch files for CCE results in several function declaration errors.

Charm++ is not built with any optimisation flags, but this does not seem to impact NAMD performance. When the NAMD build process uses the Charm compiler, it will add its own optimisations flags.

## Run notes

We use the `STMV` benchmark, which can be downloaded form the [NAMD Utilities page](https://www-s.ks.uiuc.edu/Research/namd/utilities/). According to that page, this benchmark is "useful for demonstrating scaling to thousands of processors". It is also (likely) the one that was used for the 2nd Isambard Hackathon.

Another popular benchmark is `ApoA1`, which is also available to download from the same page, but it is a much smaller test case, and so results are not as convincing. For reference, `STMV` takes about 100 seconds on 44 BDW cores, whereas `ApoA1` takes aroud 10.

Running with more than 1 thread/core produces slightly (10-15%) better results on both TX2 and x86.

## More scripts

These scripts are not useful for the main benchmark runs. However, they were used at some point and led to slower results, and they may be useful again in the future.

Note that the CCE scripts do not currently produce a complete build due to compiler errors (which seem unrelated to the build parameters).

