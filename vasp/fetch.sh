#!/bin/bash

if [ ! -r vasp.5.4.4.tar.gz ]
then
    echo
    echo "Download vasp.5.4.4.tar.gz into the current directory."
    echo
    exit 1
fi

if [ ! -e vasp-test-suite ]
then
  echo
  echo "Clone vasp-test-suite into the current directory."
  echo
fi
