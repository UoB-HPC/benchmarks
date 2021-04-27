#!/bin/bash
# shellcheck disable=SC2034 disable=SC2153

set -eu

setup_env() {
  module use /lus/scratch/p02639/modulefiles
  module use /lus/snx11029/p02508-modules/modulefiles

  module swap craype-{broadwell,x86-skylake}

  case "$COMPILER" in
    aocc-2.3)
      module swap PrgEnv-{cray,gnu}
      module load aocc/2.3
      MAKE_OPTS='COMPILER=CLANG ARCH=skylake-avx512 WGSIZE=256'
      ;;
    cce-10.0)
      module load PrgEnv-cray
      module swap cce cce/10.0.0
      MAKE_OPTS='COMPILER=CLANG CC=cc ARCH=skylake-avx512 WGSIZE=256'
      ;;
    gcc-9.3)
      module swap PrgEnv-{cray,gnu}
      module swap gcc gcc/9.3.0
      MAKE_OPTS='COMPILER=GNU ARCH=skylake-avx512 WGSIZE=256'
      ;;
    gcc-10.1)
      module swap PrgEnv-{cray,gnu}
      module swap gcc gcc/10.1.0
      MAKE_OPTS='COMPILER=GNU ARCH=skylake-avx512'
      ;;
    intel-2019)
      module swap PrgEnv-{cray,intel}
      MAKE_OPTS='COMPILER=INTEL ARCH=skylake-avx512 WGSIZE=256'
      ;;
    *)
      echo
      echo "Invalid compiler '$COMPILER'."
      usage
      exit 1
      ;;
  esac
}
export -f setup_env

script="$(realpath "$0")"
SCRIPT_DIR="$(realpath "$(dirname "$script")")"
PLATFORM_DIR="$(realpath "$(dirname "$script")")"
export SCRIPT_DIR PLATFORM_DIR

export COMPILERS="aocc-2.3 cce-10.0 gcc-9.3 gcc-10.1 intel-2019"
export DEFAULT_COMPILER="cce-10.0"
export PLATFORM="skl-swan"

bash "$PLATFORM_DIR/../common.sh" "$@"
