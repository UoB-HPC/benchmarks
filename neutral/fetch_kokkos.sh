#!/bin/bash

if [ ! -e neutral_kokkos/neutral.cpp ]
then
    git clone https://github.com/Codrin-Popa/neutral_kokkos.git
    if [ $# -lt 1 ]
    then
        usage
        exit
    fi
    
    if [ $1 == 'GPU' ]
    then
        cd neutral_kokkos
        git checkout over_events
    fi
fi
