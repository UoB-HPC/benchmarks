#!/bin/bash

DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./fetch [MODEL]"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  kokkos"
    echo
    echo "The default programming model is '$DEFAULT_MODEL'."
    echo
}

# Process arguments
MODEL=${1:-$DEFAULT_MODEL}

case "$MODEL" in
  omp)
    if [ ! -e CloverLeaf_ref/clover.f90 ]
    then
        git clone https://github.com/UK-MAC/CloverLeaf_ref
    fi
    ;;
  kokkos)
    if [ ! -e CloverLeaf/src/kokkosdefs.h ]
    then
      git clone https://github.com/UoB-HPC/CloverLeaf
    fi
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'."
    usage
    exit 1
    ;;
esac
