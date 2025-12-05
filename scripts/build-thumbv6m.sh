#!/bin/bash

# Build a sysroot and Clang config file for the thumbv6m architecture (Cortex-M0
# etc).
# TODO generalize this file to other architectures.

set -e

mkdir -p build/thumbv6m
cd build/thumbv6m

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

meson setup --cross-file ./picolibc/cross.txt --prefix="$(realpath ./picolibc)" "$SOURCE/lib/picolibc" ./picolibc/build

echo
echo "🔨 Compiling picolibc"
ninja -C picolibc/build install

echo
echo "🔨 Removing picolibc build files"
rm -r picolibc/build

# Build LLVM bits
# ===============

rm -rf llvm
mkdir -p llvm/build

LLVM_TARGET=armv6m-none-eabi
LLVM_FLAGS="-mthumb -fshort-enums -nostdlib -nostdlibinc -isystem ../../picolibc/include"

echo
echo "🔨 Configuring LLVM runtimes"
cmake $SOURCE/lib/llvm-project/runtimes \
    -B llvm/build \
    -G Ninja \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;compiler-rt" \
    -DCMAKE_ASM_COMPILER_TARGET=$LLVM_TARGET \
    -DCMAKE_ASM_FLAGS="$LLVM_FLAGS" \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_CXX_COMPILER_TARGET=$LLVM_TARGET \
    -DCMAKE_CXX_FLAGS="$LLVM_FLAGS" \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_C_COMPILER_TARGET=$LLVM_TARGET \
    -DCMAKE_C_FLAGS="$LLVM_FLAGS" \
    -DCMAKE_INSTALL_PREFIX=llvm \
    -DCOMPILER_RT_BAREMETAL_BUILD=ON \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
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
ninja -C llvm/build install

echo
echo "🔨 Removing LLVM build files"
rm -r llvm/build

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

# Add picolibc.
-isystem <CFGDIR>/picolibc/include
--sysroot=<CFGDIR>/picolibc \$-lc

# Add compiler-rt library.
\$<CFGDIR>/llvm/lib/linux/libclang_rt.builtins-armv6m.a

# Link using ld.lld
# Note that we can't use the dollar prefix here, see:
# https://github.com/llvm/llvm-project/issues/170847
-fuse-ld=lld

EOM
