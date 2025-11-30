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

## Usage

Using this sysroot is very simple. Once you've downloaded one of the sysroots and extracted it, all you need to do is to pass the right `--config` parameter. So for example, assuming you've put a release binary in sysroots/thumbv6m, you can use a command like this:

    clang --config=sysroots/thumbv6m/clang.txt -c -o file.o file.c -O2

This sets up the target, the include paths, etc. so the native Clang works like a cross compilation toolchain.
