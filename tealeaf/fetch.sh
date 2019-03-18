#!/bin/bash

DEFAULT_MODEL=omp
function usage
{
  echo
  echo "Usage: ./fetch [MODEL]"
  echo
  echo "Valid models:"
  echo " omp"
  echo " omp-target"
  echo " acc"
  echo " kokkos"
  echo " raja"
  echo " opencl"
  echo
  echo "The default programming model is '$DEFAULT_MODEL'."
  echo
}

# Process arguments
if [ $# -lt 1 ]
then
  usage
  exit 1
fi

MODEL=${1:-$DEFAULT_MODEL}

case "$MODEL" in
  omp)
    if [ ! -e TeaLeaf_ref/tea.f90 ]
    then
      git clone https://github.com/UK-MAC/TeaLeaf_ref
    fi
    ;;
  kokkos|omp-target|acc|raja)
    if [ ! -e TeaLeaf/2d/main.c ]
    then
      git clone https://github.com/UoB-HPC/TeaLeaf
      mkdir -p TeaLeaf/2d/Benchmarks
      wget https://raw.githubusercontent.com/UK-MAC/TeaLeaf_ref/master/Benchmarks/tea_bm_5.in
      mv tea_bm_5.in TeaLeaf/2d/Benchmarks
    fi
    ;;
  cuda)
    if [ ! -e TeaLeaf_CUDA/tea.f90 ]
    then
      git clone https://github.com/UK-MAC/TeaLeaf_CUDA 
    fi
    ;;
  opencl)
    if [ ! -e TeaLeaf_OpenCL/tea.f90 ]
    then
      git clone https://github.com/UK-MAC/TeaLeaf_OpenCL
    fi
    ;;
  *)
    echo
    echo "Invalid model '$MODEL'."
    usage
    exit 1
    ;;
esac

