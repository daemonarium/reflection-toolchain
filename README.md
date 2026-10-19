# reflection-toolchain

A Docker build that produces a C++ sysroot with static reflection, and an Emscripten that uses that same compiler for WebAssembly.

The result is a `sysroot/` directory. Point CMake at the toolchain files in `toolchain/` and set `P2996_COMPILER_SYSROOT` to that directory.

## Why this exists

[P2996](https://wg21.link/p2996) static reflection (`^^`, splices, `std::meta`) is not in upstream Clang. Bloomberg keeps the implementation on [clang-p2996](https://github.com/bloomberg/clang-p2996). Daemonarium's C++ serialization and RPC read class members, function parameters, and `[[=...]]` annotations through that API, so a stock Clang cannot build them.

Emscripten ships its own Clang and its own libc++. That Clang has no reflection, and its libc++ is patched so the library can be compiled to wasm. To compile reflection code to WebAssembly both have to be true at once: the compiler is clang-p2996, and the libc++ that Emscripten builds still has the wasm patches. The Dockerfile does that by replacing `emscripten/system/lib/libcxx` with clang-p2996's libc++, then copying these files back from the Emscripten original:

- `include/__config_site`
- `include/__config_site.in`
- `include/__assertion_handler`
- `src/new.cpp`
- `src/include/overridable_function.h`

That replacement is the patch this repository carries. The upstream trees are not forked.

Native code needs the same Clang, plus the libc++ / libc++abi / libunwind that were built with it. The exported sysroot also contains a Debian userland. That dump is deliberate: a native link of a normal program needs the system libraries that live next to this libc++, and a trimmed sysroot that still links has not been worked out. `sysroot/` is produced on the machine that runs the Docker build. It is not committed. See `TODO.md`.

## What is pinned

Newer upstream revisions have already failed to build this combination. `upstream-commits.txt` is the list, and the Dockerfile defaults match it.

| Piece | Pin | Where it came from |
| --- | --- | --- |
| clang-p2996 | `f72d85e5a0fd9c960b07b6f1c8875110701cb627` | `clang --version` in a working sysroot (21.0.0git) |
| emscripten | tag `4.0.21` | the export reported `4.0.21-git`; `.git` was not exported, so the release tag is the pin |
| binaryen | `ecf25d6e6d20d2018c4897dcf95babdb16e7d311` | `wasm-opt --version` reported `version_125-5-gecf25d6e6` |
| Node.js | 20.x | nodesource `setup_20.x` (the working image had 20.19.6) |
| Debian | `12.11-slim` | the base image of that sysroot |

Emscripten 4.0.21 expects a newer LLVM than this Clang and prints a version-check warning. The warning is expected for this pin. Do not bump a row because a newer tag exists. Bump it when `./run-smoke.sh` still passes on a clean rebuild.

## Build the sysroot

Docker is required. The build compiles Clang, so it takes a long time and a lot of disk.

```
./build-sysroot.sh
export P2996_COMPILER_SYSROOT=$PWD/sysroot
```

`build-sysroot.sh` reads `upstream-commits.txt`, builds the image `reflection-toolchain`, and exports `sysroot/`. It also copies `toolchain/*.cmake` into `sysroot/toolchain/` so a unpacked sysroot still carries the files CMake needs.

## Use it from CMake

Native:

```
export P2996_COMPILER_SYSROOT=$PWD/sysroot
cmake -B build -S . \
  -DCMAKE_TOOLCHAIN_FILE=$PWD/toolchain/p2996-toolchain.cmake
```

WebAssembly:

```
export P2996_COMPILER_SYSROOT=$PWD/sysroot
cmake -B build-web -S . \
  -DCMAKE_TOOLCHAIN_FILE=$PWD/toolchain/emscripten-p2996-toolchain.cmake
```

`P2996_COMPILER_SYSROOT` may be the environment variable or `-DP2996_COMPILER_SYSROOT=...`. If neither is set, the toolchain files look for `sysroot/` in the top-level source directory.

`toolchain/P2996Toolchain.cmake` is the other shape: a project that already has a compiler and only wants `configure_p2996_compiler()` / `apply_p2996_target()`. It reads the same variable.

The flags the toolchain files put on every C++ compile are:

```
-std=c++26 -freflection -fparameter-reflection -fannotation-attributes -fexpansion-statements
```

Native compiles also pass `-nostdinc++` and the sysroot's libc++ include path, and link `-lc++ -lc++abi -lunwind`.

## Compile inside the image

Building the image is enough to compile without installing the sysroot on the host. The image sets `EM_CONFIG` to its own `.emscripten`. An `EM_CONFIG` from the host is not the supported path.

```
docker build -t reflection-toolchain .
docker run --rm -v "$PWD:/work" -w /work reflection-toolchain \
  em++ -std=c++26 -freflection -fparameter-reflection \
  -fannotation-attributes -fexpansion-statements hello.cpp -o hello.html
```

Publishing that image, and shipping a prebuilt sysroot tarball, are in `TODO.md`.

## Check that the features work

`./run-smoke.sh` builds the sysroot if it is missing, then compiles and runs a small program for each feature, natively and with Emscripten:

| Program | Feature |
| --- | --- |
| `smoke/01_reflection.cpp` | `^^` and `std::meta::nonstatic_data_members_of` |
| `smoke/02_parameter_reflection.cpp` | `std::meta::parameters_of` |
| `smoke/03_annotation_attributes.cpp` | `[[=...]]` and `std::meta::extract` |
| `smoke/04_expansion_statements.cpp` | `template for` over members |
| `smoke/05_libcxx.cpp` | `std::vector`, `std::string`, `std::ranges`, `std::format` |
| `smoke/06_wasm_export.cpp` | `EMSCRIPTEN_KEEPALIVE` around a reflected value (wasm only) |

Each program prints a line starting with `OK` and returns 0. A pin that fails this script is not a pin.

## License

MIT for the build layer. Upstream licenses are in `NOTICE`.
