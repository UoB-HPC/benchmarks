#!/bin/bash

DIR="$PWD/SNAP"
if [ $# -gt 0 ]
then
    DIR="$1"
fi

if [ ! -r "$DIR/src/csnap-tx2" ]
then
    echo "Directory '$DIR' does not exist or does not contain csnap-tx2"
    exit 1
fi

cd $DIR/src

cat ../../benchmark.in \
    | sed 's/NY/16/' \
    | sed 's/NZ/16/' \
    | sed 's/NPEY/8/' \
    | sed 's/NPEZ/8/' \
    | sed 's/NTHREADS/4/' \
    | sed 's/ICHUNK/16/' \
    >tx2.in

module swap cce cce/8.6.4

export OMP_NUM_THREADS=4
mpirun -np 64 --bind-to core ./csnap-tx2 tx2.in tx2.out
cat tx2.out
