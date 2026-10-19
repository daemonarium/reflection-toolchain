#!/usr/bin/env bash
# Build the sysroot if needed, then run every smoke test natively and as wasm.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -x "$PWD/sysroot/usr/local/bin/clang++" ]; then
  ./build-sysroot.sh
fi
export P2996_COMPILER_SYSROOT="$PWD/sysroot"

pass=0
fail=0
failed=()

record() {
  local kind="$1"
  local name="$2"
  local ok="$3"
  if [ "$ok" -eq 0 ]; then
    pass=$((pass + 1))
    printf '  %-8s %-28s OK\n' "$kind" "$name"
  else
    fail=$((fail + 1))
    failed+=("$kind:$name")
    printf '  %-8s %-28s FAIL\n' "$kind" "$name"
  fi
}

run_one() {
  local kind="$1"
  local name="$2"
  shift 2
  local out
  if out=$("$@" 2>&1) && printf '%s\n' "$out" | grep -q '^OK '; then
    record "$kind" "$name" 0
  else
    record "$kind" "$name" 1
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
}

jobs=$(nproc)

echo "== native =="
cmake -B smoke/build -S smoke \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/toolchain/p2996-toolchain.cmake"
cmake --build smoke/build -j"$jobs"
for name in 01_reflection 02_parameter_reflection 03_annotation_attributes 04_expansion_statements 05_libcxx; do
  run_one native "$name" "smoke/build/$name"
done

echo "== wasm =="
cmake -B smoke/build-web -S smoke \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/toolchain/emscripten-p2996-toolchain.cmake"
cmake --build smoke/build-web -j"$jobs"
for name in 01_reflection 02_parameter_reflection 03_annotation_attributes 04_expansion_statements 05_libcxx 06_wasm_export; do
  run_one wasm "$name" node "smoke/build-web/${name}.js"
done

echo
echo "pass=$pass fail=$fail"
if [ "$fail" -ne 0 ]; then
  printf 'failed: %s\n' "${failed[@]}"
  exit 1
fi
