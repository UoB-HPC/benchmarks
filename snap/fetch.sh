#!/bin/bash

DEFAULT_MODEL=omp
function usage
{
    echo
    echo "Usage: ./fetch [MODEL]"
    echo
    echo "Valid models:"
    echo "  omp"
    echo " kokkos"
    echo
    echo "The default programming model is '$DEFAULT_MODEL'."
    echo
}

MODEL=${1:-$DEFAULT_MODEL}

case "$MODEL" in
  omp)
    if [ ! -e SNAP/src/snap_main.f90 ]
    then
        git clone https://github.com/lanl/SNAP
    fi
    ;;
  kokkos)
    if [ ! -e SNAP-Kokkos/src/ext_sweep.cpp ]
    then
      git clone https://github.com/UoB-HPC/SNAP-Kokkos
    fi
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'."
    usage
    exit 1
    ;;
esac

