#!/bin/bash

if [ ! -e NEMOGCM/cfgs/GYRE_PISCES ]
then
    # TODO: Update to release branch when 4.0 is released
    svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/trunk NEMOGCM
fi
