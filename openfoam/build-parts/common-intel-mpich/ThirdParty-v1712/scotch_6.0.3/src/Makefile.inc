#-------------------------------*- makefile -*---------------------------------
# OpenFOAM notes:
#
# WM_CFLAGS, WM_LDFLAGS contain "-m32 -fPIC" etc
# WM_LABEL_SIZE == 64 for 'long' instead of 'int' for OpenFOAM labels
#
# - compiled without pthread
#
# Normally set CCS, CCP by caller

EXE         =
LIB         = .so
OBJ         = .o

CC          = icc
AR          = $(CC)
ARFLAGS     = $(WM_CFLAGS) -shared -o
CCS        ?= $(CC)
# CCP        ?= mpicc
CCP         = icc
CCD         = $(CCP)
CFLAGS      = $(WM_CFLAGS) -O3 \
    -DCOMMON_FILE_COMPRESS_GZ \
    -DCOMMON_RANDOM_FIXED_SEED \
    -DSCOTCH_DETERMINISTIC \
    -DSCOTCH_RENAME \
    -Drestrict=__restrict \
    -I/opt/cray/pe/mpt/7.7.0/gni/mpich-intel/16.0/include

# 32-bit vs. 64-bit labels
ifeq ($(WM_LABEL_SIZE),64)
CFLAGS     += -DINTSIZE64
endif

CLIBFLAGS   = -shared
LDFLAGS     = -Xlinker --no-as-needed $(WM_LDFLAGS) -lz -lm -lrt \
    -L/opt/cray/pe/mpt/7.7.0/gni/mpich-intel/16.0/lib -lmpich

MAKE        = make
CP          = cp
CAT         = cat
LN          = ln
MKDIR       = mkdir
MV          = mv
RANLIB      = echo
LEX         = flex -Pscotchyy -olex.yy.c
YACC        = bison -pscotchyy -y -b y

#------------------------------------------------------------------------------
