#!/bin/bash

[[ $# -ne 1 ]] && echo "need new version" && exit 1

echo -n "$1" > src/version.txt

zig build -Dtarget=native-native-musl -Doptimize=ReleaseFast
cp zig-out/bin/chexdiff .
gzip -f --best chexdiff
