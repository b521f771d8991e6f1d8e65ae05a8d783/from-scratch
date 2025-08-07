#! /usr/bin/env zsh

# extensive test suite for all build scenarios
set -e

make clean
docker build .
docker build . --target build-nix
nix build . -L --show-trace
make init && npx dotenvx run -- make all