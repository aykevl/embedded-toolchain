#!/bin/bash

# Build a sysroot and Clang config file for the thumbv6m architecture (Cortex-M0
# etc).
# TODO generalize this file to other architectures.

set -e

mkdir -p build/thumv6m
cd build/thumv6m

SOURCE="$(realpath ../..)"

# Build picolibc
# ==============
#
# This must be done before the LLVM runtimes are built, since the runtimes
# depend on a libc.

rm -rf picolibc
mkdir picolibc

echo "🔨 Configuring picolibc"

# Create a cross compilation file for Meson.
cat > picolibc/cross.txt <<- EOM
[binaries]
c = 'clang'
strip = 'llvm-strip'

[host_machine]
system = 'unknown'
cpu_family = 'arm'
cpu = 'arm'
endian = 'little'

[built-in options]
c_args = ['--target=thumbv6m-unknown-none-eabi', '-Werror=double-promotion', '-Wno-unsupported-floating-point-opt', '-fshort-enums']
c_link_args = ['--target=thumbv6m-unknown-none-eabi', '-fuse-ld=lld', '-nostdlib']

[properties]
skip_sanity_check = true
EOM

meson setup --cross-file ./picolibc/cross.txt "$SOURCE/lib/picolibc" ./picolibc

echo
echo "🔨 Compiling picolibc"
meson compile -C picolibc

# Build LLVM bits
# ===============

rm -rf llvm
mkdir llvm

LLVM_FLAGS="--target=thumbv6m-unknown-none-eabi -fshort-enums -nostdlib -nostdlibinc -isystem ../picolibc -isystem $SOURCE/lib/picolibc/newlib/libc/include -isystem $SOURCE/lib/picolibc/newlib/libc/tinystdio"

echo
echo "🔨 Configuring LLVM runtimes"
cmake $SOURCE/lib/llvm-project/runtimes \
    -B llvm \
    -G Ninja \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;compiler-rt" \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_FLAGS="$LLVM_FLAGS" \
    -DCMAKE_CXX_FLAGS="$LLVM_FLAGS" \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DLIBCXXABI_BAREMETAL=ON \
    -DLIBCXXABI_ENABLE_SHARED=OFF \
    -DLIBCXXABI_ENABLE_THREADS=OFF \
    -DLIBCXXABI_USE_LLVM_UNWINDER=OFF \
    -DLIBCXX_ABI_UNSTABLE=ON \
    -DLIBCXX_ENABLE_FILESYSTEM=OFF \
    -DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF \
    -DLIBCXX_ENABLE_SHARED=OFF \
    -DLIBCXX_ENABLE_THREADS=OFF

echo
echo "🔨 Building LLVM runtimes"
ninja -C llvm

# Create Clang configuration file
# ===============================

cat > clang.txt <<- EOM
# Clang configuration file.
# Use 'clang --config=path/to/clang.txt' to use this sysroot.

# Select the right architecture/ABI etc.
--target=thumbv6m-unknown-none-eabi -fshort-enums

# Don't use standard library files.
-nostdlib -nostdlibinc

# Add libc++ to the include path.
-isystem <CFGDIR>/llvm/include/c++/v1

# Add picolibc to the include path.
-isystem <CFGDIR>/picolibc
-isystem <CFGDIR>/../../lib/picolibc/newlib/libc/include
-isystem <CFGDIR>/../../lib/picolibc/newlib/libc/tinystdio

EOM
