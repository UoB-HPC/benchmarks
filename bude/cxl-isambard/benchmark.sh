#!/bin/bash
# shellcheck disable=SC2034 disable=SC2153

set -eu

setup_env() {
  if ! grep -q bristol/modules/ <<<"$MODULEPATH"; then
    module use /lustre/projects/bristol/modules/modulefiles
  fi

  case "$COMPILER" in
    aocc-2.3)
      module load aocc/2.3
      MAKE_OPTS='COMPILER=CLANG ARCH=skylake-avx512 WGSIZE=128'
      ;;
    cce-10.0)
      module load PrgEnv-cray
      module swap cce cce/10.0.0
      module swap craype-{broadwell,x86-skylake}
      MAKE_OPTS='COMPILER=CLANG CC=cc ARCH=skylake-avx512 WGSIZE=128'
      ;;
    gcc-9.3)
      module load gcc/9.3.0
      MAKE_OPTS='COMPILER=GNU ARCH=skylake-avx512 WGSIZE=128'
      ;;
    gcc-10.2)
      module load gcc/10.2.0
      MAKE_OPTS='COMPILER=GNU ARCH=skylake-avx512 WGSIZE=128'
      ;;
    intel-2019)
      module load intel-parallel-studio-xe/compilers/64/2019u4/19.0.4
      MAKE_OPTS='COMPILER=INTEL ARCH=skylake-avx512 WGSIZE=128'
      ;;
    intel-2020)
      module load intel-parallel-studio-xe/compilers/64/2020u4/20.0.4
      MAKE_OPTS='COMPILER=INTEL ARCH=skylake-avx512 WGSIZE=128'
      ;;
    llvm-11.0)
      module load llvm/11.0
      MAKE_OPTS='COMPILER=GNU ARCH=skylake-avx512 WGSIZE=128'
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

export COMPILERS="aocc-2.3 cce-10.0 gcc-9.3 gcc-10.2 intel-2019 intel-2020 llvm-11.0"
export DEFAULT_COMPILER="cce-10.0"
export PLATFORM="cxl-isambard"

bash "$PLATFORM_DIR/../common.sh" "$@"
