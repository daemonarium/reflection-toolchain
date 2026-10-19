#!/usr/bin/env bash
# Build the image from the pins in upstream-commits.txt and export sysroot/.
set -euo pipefail
cd "$(dirname "$0")"

args=()
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ''|\#*) continue ;;
  esac
  args+=(--build-arg "$line")
done < upstream-commits.txt

echo "Building reflection-toolchain image"
docker build --progress=plain "${args[@]}" . -t reflection-toolchain

echo "Exporting sysroot"
mkdir -p sysroot
docker run --rm -v "$PWD/sysroot:/sysroot" reflection-toolchain /export-sysroot.sh

echo "Writing emscripten config"
cat > sysroot/.emscripten << EOF
EMSCRIPTEN_ROOT = '$PWD/sysroot/emscripten'
LLVM_ROOT = '$PWD/sysroot/usr/local/bin'
BINARYEN_ROOT = '$PWD/sysroot/usr/local/bin'
EM_CACHE = '$PWD/sysroot/emscripten/cache'
EOF

mkdir -p sysroot/toolchain
cp toolchain/*.cmake sysroot/toolchain/

echo "Sysroot exported"
echo "export P2996_COMPILER_SYSROOT=$PWD/sysroot"
