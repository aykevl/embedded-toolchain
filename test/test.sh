#!/bin/sh

set -e

echo "::group::Clang version"
clang --version
echo "::endgroup::"

echo "::group::Test C thumbv6m"
clang --config=build/thumbv6m/clang.cfg -o test/basic-c-thumbv6m.elf test/basic.c -O2
llvm-size test/basic-c-thumbv6m.elf
echo "::endgroup::"

echo "::group::Test C++ thumbv6m"
clang++ --config=build/thumbv6m/clang++.cfg -o test/basic-cpp-thumbv6m.elf test/basic.cpp -O2
llvm-size test/basic-cpp-thumbv6m.elf
echo "::endgroup::"
