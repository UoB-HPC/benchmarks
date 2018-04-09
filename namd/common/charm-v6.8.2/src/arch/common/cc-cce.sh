CMK_DEFS=''

CMK_CPP_CHARM='cpp -P'
CMK_CPP_C='cc -E '
CMK_CC="cc -h pic "
CMK_CXX="CC -h pic "
CMK_CXX_OPTIMIZE=" -hipa4"   # For improved C++ performance
CMK_LIBS='-lckqt'

CMK_LD="eval $CMK_CC "
CMK_LDXX="CC "

CMK_QT="generic64-light"

CMK_LD_LIBRARY_PATH="-Wl,-rpath,$CHARMLIBSO/"
CMK_NATIVE_CC="gcc -fPIC "
CMK_NATIVE_CXX="g++ -fPIC "
CMK_NATIVE_LD="gcc "
CMK_NATIVE_LDXX="g++ "
CPPFLAGS="$CPPFLAGS -h pic "
LDFLAGS="$LDFLAGS  "

CMK_CF77="ftn -h PIC "
CMK_CF90="ftn -h PIC "
CMK_F90LIBS=""
# #CMK_CF90_FIXED="$CMK_CF90 -132 -FI "
# #FOR 64 bit machine
# CMK_CF90_FIXED="$CMK_CF90 -164 -FI "
# F90DIR=`which ifort 2> /dev/null`
# if test -h "$F90DIR"
# then
#   F90DIR=`readlink $F90DIR`
# fi
# if test -x "$F90DIR"
# then
#   F90LIBDIR="`dirname $F90DIR`/../lib"
#   F90MAIN="$F90LIBDIR/for_main.o"
# fi
# # for_main.o is important for main() in f90 code
# CMK_F90MAINLIBS="$F90MAIN "
# CMK_F90LIBS="-L$F90LIBDIR -lifcore -lifport -lifcore "
# CMK_F77LIBS="$CMK_F90LIBS"

# CMK_F90_USE_MODDIR=""
CMK_F90_USE_MODDIR=1
CMK_F90_MODINC="-I"
CMK_MOD_EXT="mod"

# native compiler for compiling charmxi, etc
CMK_SEQ_CC="$CMK_NATIVE_CC"
CMK_SEQ_CXX="$CMK_NATIVE_CXX"
CMK_SEQ_LD="$CMK_NATIVE_LD"
CMK_SEQ_LDXX="$CMK_NATIVE_LDXX"

CMK_C_OPENMP="-h omp"
