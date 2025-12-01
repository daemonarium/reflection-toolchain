#!/bin/bash

echo "Building clang-p2996"
docker build --progress=plain . -t clang-p2996

echo "Exporting sysroot"
docker run --rm -v "$PWD/sysroot:/sysroot" clang-p2996 /export-sysroot.sh

echo "Sysroot exported"

echo "Creating emscripten config"
echo "EMSCRIPTEN_ROOT = '$PWD/sysroot/emscripten'" > sysroot/.emscripten
echo "LLVM_ROOT = '$PWD/sysroot/usr/local/bin'" >> sysroot/.emscripten
echo "BINARYEN_ROOT = '$PWD/sysroot/usr/local/bin'" >> sysroot/.emscripten
echo "EM_CACHE = '$PWD/sysroot/emscripten/cache'" >> sysroot/.emscripten

echo "Emscripten config created"
echo "Remember to run export EM_CONFIG=$PWD/sysroot/.emscripten"
