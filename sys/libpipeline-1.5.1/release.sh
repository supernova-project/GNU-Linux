#! /bin/sh
set -e

# Build automatically generated files
./bootstrap

# Basic configure to get 'make distcheck'
./configure

make distcheck
