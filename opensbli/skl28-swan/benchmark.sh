#!/bin/bash

function setup_env()
{
  module swap craype-{broadwell,x86-skylake}
  PRGENV=`module -t list 2>&1 | grep PrgEnv`
  case "$COMPILER" in
      cce-9.0)
          module swap $PRGENV PrgEnv-cray
          module swap cce cce/9.0.1
          module load cray-hdf5-parallel
          export OPS_COMPILER=cray
          OPS_MAKE_OPTS='MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -march=skylake-avx512 -ffp-contract=fast"'
          SBLI_MAKE_OPTS='MPICPP=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -march=skylake-avx512 -ffp-contract=fast"'
          ;;
      gcc-8.3)
          module swap $PRGENV PrgEnv-gnu
          module swap gcc gcc/8.3.0
          module load cray-hdf5-parallel
          export OPS_COMPILER=gnu
          OPS_MAKE_OPTS='MPICC=cc MPICXX=CC CXXFLAGS="-O3 -fPIC -DUNIX -Wall -ffloat-store -march=skylake-avx512 -ffp-contract=fast"'
          SBLI_MAKE_OPTS='MPICPP=CC CCFLAGS="-O3 -fPIC -DUNIX -Wall -march=skylake-avx512 -ffp-contract=fast"'
          ;;
      intel-2019)
          module swap $PRGENV PrgEnv-intel
          module swap intel intel/19.0.3.199
          module load cray-hdf5-parallel
          export OPS_COMPILER=intel
          OPS_MAKE_OPTS='MPICC=cc MPICXX=CC CXXFLAGS="-O3 -xCORE-AVX512 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div"'
          OPS_MAKE_OPTS=$OPS_MAKE_OPTS' MPIFLAGS="-O3 -xCORE-AVX512 -qopenmp -fno-alias -finline -inline-forceinline -no-prec-div -std=c99"'
          SBLI_MAKE_OPTS='MPICPP=CC CCFLAGS="-O3 -xCORE-AVX512 -fno-alias -finline -inline-forceinline -no-prec-div -fp-model strict -fp-model source -parallel"'
          ;;
      *)
          echo
          echo "Invalid compiler '$COMPILER'."
          usage
          exit 1
          ;;
  esac
}

SCRIPT="`realpath $0`"
export ARCH="skl28"
export PLATFORM_DIR="`realpath $(dirname $SCRIPT)`"
export COMPILERS="cce-9.0 gcc-8.3 intel-2019"
export DEFAULT_COMPILER=cce-9.0
export PBS_RESOURCES=":ncpus=56"
export -f setup_env

"$PLATFORM_DIR/../common.sh" "$@"
