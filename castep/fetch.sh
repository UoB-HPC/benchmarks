#!/bin/bash


# Download CASTEP
if [ ! -e castep-19.1 ]
then
    echo ""
    echo "Downloading CASTEP"
    echo ""
    module load cray-python
    pip install --user mercurial
    PATH=$PATH:~/.local/bin
    hg clone https://bitbucket.org/castep/castep-hg/src/Castep191_branch/ castep-19.1
fi

# Download CASTEP al3x3 benchmark and update cut-off energy to 700eV
if [ ! -e castep-benchmarks ]
then
    mkdir castep-benchmarks
    cd castep-benchmarks
    wget --output-document=al3x3.tar "http://www.castep.org/CASTEP/Al3x3?action=download&upname=al3x3.tgz"
    tar -xf al3x3.tar
    sed -i 's/400 eV/700 eV/g' Al2O3-slab/3x3/al3x3.param
    cd ..
fi
