#!/bin/bash

# Build a sysroot and Clang config file for the thumbv6m architecture (Cortex-M0
# etc).
# TODO generalize this file to other architectures.

set -e

rm -rf build/thumbv6m
mkdir -p build/thumbv6m
cd build/thumbv6m

SOURCE="$(realpath ../..)"

# Build picolibc
# ==============
#
# This must be done before the LLVM runtimes are built, since the runtimes
# depend on a libc.

mkdir -p build/picolibc

echo "🔨 Configuring picolibc"

# Create a cross compilation file for Meson.
cat > build/picolibc/cross.txt <<- EOM
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

meson setup --cross-file ./build/picolibc/cross.txt --prefix="$(realpath .)" "$SOURCE/lib/picolibc" ./build/picolibc

echo
echo "🔨 Compiling picolibc"
ninja -C build/picolibc install

# Build LLVM bits
# ===============

mkdir -p build/llvm

LLVM_TARGET=armv6m-none-eabi
LLVM_FLAGS="-mthumb -fshort-enums -nostdlib -nostdlibinc -isystem ../../include"

echo
echo "🔨 Configuring LLVM runtimes"
cmake $SOURCE/lib/llvm-project/runtimes \
    -B build/llvm \
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
    -DCMAKE_INSTALL_PREFIX=. \
    -DCOMPILER_RT_BAREMETAL_BUILD=ON \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
    -DLIBCXXABI_BAREMETAL=ON \
    -DLIBCXXABI_ENABLE_SHARED=OFF \
    -DLIBCXXABI_ENABLE_THREADS=OFF \
    -DLIBCXXABI_ENABLE_EXCEPTIONS=OFF \
    -DLIBCXXABI_USE_LLVM_UNWINDER=OFF \
    -DLIBCXX_ABI_UNSTABLE=ON \
    -DLIBCXX_ENABLE_FILESYSTEM=OFF \
    -DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF \
    -DLIBCXX_ENABLE_SHARED=OFF \
    -DLIBCXX_ENABLE_THREADS=OFF

echo
echo "🔨 Building LLVM runtimes"
ninja -C build/llvm install

# Cleanup
# =======

echo
echo "🔨 Removing build files"
rm -r build

# Create Clang configuration files
# ================================

# C configuration file.
cat > clang.cfg <<- EOM
# Clang configuration file.
# Use 'clang --config=path/to/clang.cfg' to use this sysroot.

# Select the right architecture/ABI etc.
--target=thumbv6m-unknown-none-eabi -fshort-enums

# Don't use standard library files.
-nostdlib -nostdlibinc

# Use the right sysroot.
-isystem <CFGDIR>/include
--sysroot=<CFGDIR> \$-lc

# Add compiler-rt library.
\$<CFGDIR>/lib/linux/libclang_rt.builtins-armv6m.a

# Link using ld.lld
# Note that we can't use the dollar prefix here, see:
# https://github.com/llvm/llvm-project/issues/170847
-fuse-ld=lld

EOM

# C++ configuration file (almost identical, the only difference is the C++
# libraries).
cat > clang++.cfg <<- EOM
# Clang C++ configuration file.
# Use 'clang++ --config=path/to/clang++.cfg' to use this sysroot.

# Select the right architecture/ABI etc.
--target=thumbv6m-unknown-none-eabi -fshort-enums

# Don't use standard library files.
-nostdlib -nostdlibinc

# Don't use exception handling.
# At the moment, we don't support libunwind.
-fno-exceptions

# Add libc++.
-isystem <CFGDIR>/include/c++/v1
\$-lc++ \$-lc++abi

# Use the right sysroot.
-isystem <CFGDIR>/include
--sysroot=<CFGDIR> \$-lc

# Add compiler-rt library.
\$<CFGDIR>/lib/linux/libclang_rt.builtins-armv6m.a

# Link using ld.lld
# Note that we can't use the dollar prefix here, see:
# https://github.com/llvm/llvm-project/issues/170847
-fuse-ld=lld

EOM
