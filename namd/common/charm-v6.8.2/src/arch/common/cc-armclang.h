#undef CMK_DLL_CC

#undef  CMK_COMPILEMODE_ORIG
#undef  CMK_COMPILEMODE_ANSI
#define CMK_COMPILEMODE_ORIG                               1
#define CMK_COMPILEMODE_ANSI                               0

#undef CMK_THREADS_USE_CONTEXT
#undef CMK_THREADS_USE_PTHREADS
#undef CMK_64BIT
#define CMK_THREADS_USE_CONTEXT                            1
#define CMK_THREADS_USE_PTHREADS                           0
#define CMK_64BIT                                          1

