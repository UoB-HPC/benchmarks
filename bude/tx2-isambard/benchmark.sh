#!/bin/bash
# shellcheck disable=SC2034 disable=SC2153

set -eu

setup_env() {
  USE_QUEUE=true
  case "$COMPILER" in
    arm-20.0)
      module swap PrgEnv-{cray,allinea}
      module swap allinea allinea/20.0.0.0
      MAKE_OPTS='COMPILER=ARM WGSIZE=256'
      ;;
    cce-10.0)
      [ -z "$CRAY_CPU_TARGET" ] && module load craype-arm-thunderx2
      module swap cce cce/10.0.1
      MAKE_OPTS='COMPILER=CLANG CC=cc WGSIZE=256'
      ;;
    cce-11.0)
      [ -z "$CRAY_CPU_TARGET" ] && module load craype-arm-thunderx2
      module swap cce cce/11.0.0.7500
      MAKE_OPTS='COMPILER=CLANG CC=cc WGSIZE=256'
      ;;
    gcc-9.3)
      module swap PrgEnv-{cray,gnu}
      module swap gcc gcc/9.3.0
      MAKE_OPTS='COMPILER=GNU WGSIZE=256'
      ;;
    llvm-11.0)
      module load llvm/11.0.0
      MAKE_OPTS='COMPILER=CLANG WGSIZE=256'
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

export COMPILERS="arm-20.0 cce-10.0 cce-11.0 gcc-9.3 llvm-11.0"
export DEFAULT_COMPILER="cce-10.0"
export PLATFORM="tx2-isambard"

bash "$PLATFORM_DIR/../common.sh" "$@"
