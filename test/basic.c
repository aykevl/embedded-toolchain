// Basic test to see whether compiler-rt and picolibc build and link correctly.

#include <math.h>

// Use volatile here to prevent the compiler from optimizing these variables.
volatile double x = 5.0;
volatile double result;

void _start(void) {
    result = sqrt(x);
}
