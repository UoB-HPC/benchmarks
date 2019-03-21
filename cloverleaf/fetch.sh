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
    echo "  opencl"
    echo "  acc"
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
    if [ ! -e CloverLeaf_CUDA/clover_leaf.f90 ]
    then
      git clone --depth 1 https://github.com/UK-MAC/CloverLeaf_CUDA.git
    fi
    ;;
  opencl)
    if [ ! -e CloverLeaf/src/opencldefs.h ]
    then
      git clone https://github.com/UoB-HPC/CloverLeaf
    fi
    ;;
  acc)
    if [ ! -e CloverLeaf-OpenACC/clover.f90 ]
    then
      git clone https://github.com/UoB-HPC/CloverLeaf-OpenACC
    fi
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'."
    usage
    exit 1
    ;;
esac
