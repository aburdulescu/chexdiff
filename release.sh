#!/bin/bash

[[ $# -ne 1 ]] && echo "need new version" && exit 1

echo -n "$1" > src/version.txt

zig build -Dtarget=native-native-musl -Drelease=true -Dstrip=true
strip -s zig-out/bin/chexdiff
cp zig-out/bin/chexdiff .
