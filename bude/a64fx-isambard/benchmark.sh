#!/bin/bash
# shellcheck disable=SC2034 disable=SC2153

set -eu

setup_env() {
  USE_QUEUE=true
  if ! grep -q bristol/modules-a64fx/ <<<"$MODULEPATH"; then
    module use /lustre/projects/bristol/modules-a64fx/modulefiles
  fi
  if ! grep -q lustre/software/aarch64/ <<<"$MODULEPATH"; then
    module use /lustre/software/aarch64/modulefiles
  fi

  case "$COMPILER" in
    arm-20.3)
      module load arm/20.3
      MAKE_OPTS='COMPILER=CLANG CC=armclang WGSIZE=128'
      ;;
    arm-21.0)
      module load tools/arm-compiler-a64fx/21.0
      MAKE_OPTS='COMPILER=CLANG CC=armclang WGSIZE=128'
      ;;
    cce-10.0)
      module unload cce-sve
      module load cce/10.0.3
      MAKE_OPTS='COMPILER=CLANG CC=cc WGSIZE=128'
      export CRAYPE_LINK_TYPE=dynamic
      ;;
    cce-sve-10.0)
      module swap cce-sve cce-sve/10.0.1
      MAKE_OPTS='COMPILER=CRAY WGSIZE=128'
      export CRAYPE_LINK_TYPE=dynamic
      ;;
    fcc-4.3)
      module load fujitsu-compiler/4.3.1
      MAKE_OPTS='COMPILER=FUJITSU WGSIZE=128 ARCH=a64fx'
      ;;
    gcc-8.1)
      module load gcc/8.1.0
      MAKE_OPTS='COMPILER=GNU WGSIZE=128'
      ;;
    gcc-11.0)
      module load gcc/11-20210321
      MAKE_OPTS='COMPILER=GNU WGSIZE=128'
      ;;
    llvm-11.0)
      module load llvm/11.0
      MAKE_OPTS='COMPILER=CLANG WGSIZE=128'
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

export COMPILERS="arm-20.3 arm-21.0 cce-10.0 cce-sve-10.0 fcc-4.3 gcc-8.1 gcc-11.0 llvm-11.0"
export DEFAULT_COMPILER="fcc-4.3"
export PLATFORM="a64fx-isambard"

bash "$PLATFORM_DIR/../common.sh" "$@"
