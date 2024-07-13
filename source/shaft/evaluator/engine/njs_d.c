
__import core.stdc.math;

// dmd 2.107.1 (ldc 1.37.0) and earlier
//#define __builtin_signbit signbit

// dmd 2.108.0 (ldc 1.38.0) and later
#define __builtin_signbit __signbit

#include <njs_main.h>
