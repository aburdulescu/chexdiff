#!/bin/bash

zig build -Drelease=true

valgrind --tool=cachegrind --cachegrind-out-file=cg.out ./zig-out/bin/chexdiff ffaa ffab

cg_annotate --show=Ir cg.out $PWD/src/main.zig > cg_annotate.out
