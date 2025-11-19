# Embedded toolchain

Work-in-progress embedded toolchain, so you can easily compile for a baremetal system using a system Clang.

Goals:

  * Provide a sysroot for compiling to various embedded platforms.
  * C and C++ support.
  * Single parameter you pass to Clang, no configuration needed.
  * Script to build a new sysroot with custom options from scratch.

Non-goals:

  * Support other compilers than Clang.
  * Have a stable ABI. If you upgrade the sysroot, you need to recompile.
  * Provide binaries. This is a portable sysroot that can be used with any Clang.
  * Provide code for specific chips or chip families. This project focuses on major architectures like thumbv6m, thumbv7em, etc, not on initializing clocks for specific chips for example.
