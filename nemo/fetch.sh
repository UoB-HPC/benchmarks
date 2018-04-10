#!/bin/bash

if [ ! -r xios-1.0/make_xios ]
then
    svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/branchs/xios-1.0@703 xios-1.0
fi

if [ ! -r NEMOGCM/CONFIG/GYRE_PISCES/cpp_GYRE_PISCES.fcm ]
then
    echo "Checkout NEMO source, e.g.:"
    echo "svn --username <user> co http://forge.ipsl.jussieu.fr/nemo/svn/branches/2015/nemo_v3_6_STABLE/NEMOGCM"
fi
