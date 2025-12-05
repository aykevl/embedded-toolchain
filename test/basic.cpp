// Basic test to see whether C++ works.

#include <algorithm>
#include <array>

// Use volatile here to prevent the compiler from optimizing these variables.
volatile int one = 1;
volatile int result;

extern "C"
void _start(void) {
    // Create a vector.
    std::array<int, 2> s{one, 0};

    // Sort it.
    std::sort(s.begin(), s.end());

    // Make sure the compiler is forced to calculate the result.
    result = s[0];
}
