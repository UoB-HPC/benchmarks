# Platform specific settings
#-------------------------------------------------------------------------------

# Make
#-----
# Make command
MAKE=make

# Fortran
#--------
# Compiler command
FC=${FCM_FTN}
# Precision flags (passed to all compilation commands)
FCFLAGS_PREC=
# Flag used to set OpenMP (passed to all compilation commands)
FCFLAGS_OPENMP=-fopenmp
# Flag used to unset OpenMP (passed to all compilation commands)
FCFLAGS_NOOPENMP=
# Any other flags (to be passed to all compliation commands)
FCFLAGS_EXTRA=-std=f2003 -pedantic -pedantic-errors -fno-range-check
# Flag used to set PIC (Position-independent-code; required by dynamic lib 
# and so will only be passed to compile objects destined for the dynamic lib)
FCFLAGS_PIC=-fPIC
# Flags used to toggle the building of a dynamic (shared) library
FCFLAGS_SHARED=-shared
# Flags used for compiling a dynamically linked test executable; in some cases
# control of this is argument order dependent - for these cases the first 
# variable will be inserted before the link commands and the second will be
# inserted afterwards
FCFLAGS_DYNAMIC=-dynamic
FCFLAGS_DYNAMIC_TRAIL=-Wl,-rpath=${LIBDIR_OUT}/lib
# Flags used for compiling a statically linked test executable (following the
# same rules as the dynamic equivalents - see above comment)
FCFLAGS_STATIC=
FCFLAGS_STATIC_TRAIL=

# C
#--
# Compiler command
CC=${FCM_CC}
# Precision flags (passed to all compilation commands)
CCFLAGS_PREC=
# Flag used to set OpenMP (passed to all compilation commands)
CCFLAGS_OPENMP=-fopenmp
# Flag used to unset OpenMP (passed to all compilation commands)
CCFLAGS_NOOPENMP=-Wno-unknown-pragmas
# Any other flags (to be passed to all compilation commands)
CCFLAGS_EXTRA=-std=c99 -Wall -Wextra -Werror -Wformat=2 -Winit-self -Wfloat-equal   \
              -Wpointer-arith -Wbad-function-cast -Wcast-qual -Wcast-align          \
              -Wconversion -Wlogical-op -Wstrict-prototypes -Wmissing-declarations  \
              -Wredundant-decls -Wnested-externs -Woverlength-strings               \
              -fdiagnostics-show-option
# Flag used to set PIC (Position-independent-code; required by dynamic lib 
# and so will only be passed to compile objects destined for the dynamic lib)
CCFLAGS_PIC=-fPIC

# Archiver
#---------
# Archiver command
AR=ar -rc

# Set the name of this platform; this will be included as the name of the 
# top-level directory in the build
PLATFORM=build-gnu

# Proceed to include the rest of the common makefile
include ${DIR_ROOT}/Makefile