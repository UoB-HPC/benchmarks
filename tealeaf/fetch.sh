#!/bin/bash

if [ ! -e TeaLeaf_ref/tea.f90 ]
then
    git clone https://github.com/UK-MAC/TeaLeaf_ref
    cd TeaLeaf_ref
    git checkout v1.403
fi
