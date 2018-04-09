. $CHARMINC/cc-armclang.sh

CMK_DEFS=' -D_REENTRANT '

CMK_XIOPTS=''
CMK_LIBS="-lpthread $CMK_LIBS"

# native compiler for compiling charmxi, etc
CMK_NATIVE_CC="$CMK_CC $CMK_DEFS "
CMK_NATIVE_CXX="$CMK_CXX $CMK_DEFS "
CMK_NATIVE_LD="$CMK_CC $CMK_DEFS "
CMK_NATIVE_LDXX="$CMK_CXX $CMK_DEFS "

# native compiler for compiling charmxi, etc
CMK_SEQ_CC="$CMK_NATIVE_CC"
CMK_SEQ_CXX="$CMK_NATIVE_CXX"
CMK_SEQ_LD="$CMK_NATIVE_LD"
CMK_SEQ_LDXX="$CMK_NATIVE_LDXX"

CMK_QT='generic64-light'

CMK_SMP='1'
