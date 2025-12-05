#!/bin/sh

set -e

echo "::group::Clang version"
clang --version
echo "::endgroup::"

echo "::group::Test basic thumbv6m"
clang --config=build/thumbv6m/clang.txt -o test/basic-thumbv6m.elf test/basic.c -O2
llvm-size test/basic-thumbv6m.elf
echo "::endgroup::"
