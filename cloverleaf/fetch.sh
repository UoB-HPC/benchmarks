#!/bin/bash

DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./fetch [MODEL]"
    echo
    echo "Valid models:"
    echo "  omp"
    echo "  omp-target"
    echo "  kokkos"
    echo "  cuda"
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
  omp-target)
    if [ ! -e CloverLeaf-OpenMP4/clover.f90 ]
    then
        # TODO: this is temporary until https://github.com/UoB-HPC/CloverLeaf-OpenMP4/pull/1 is merged
        git clone https://github.com/jlsalmon/CloverLeaf-OpenMP4
        # git clone https://github.com/UoB-HPC/CloverLeaf-OpenMP4
    fi
    ;;
  kokkos)
    if [ ! -e CloverLeaf/src/kokkosdefs.h ]
    then
      git clone https://github.com/UoB-HPC/CloverLeaf
    fi
    ;;
  cuda)
    if [ ! -e CloverLeaf/src/cudadefs.h ]
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
