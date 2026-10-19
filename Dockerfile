# Reflection toolchain image.
# Upstream pins live in upstream-commits.txt and are passed as build args.
# Defaults below match that file.

ARG DEBIAN_TAG=12.11-slim
FROM debian:${DEBIAN_TAG}

ARG P2996_COMMIT=f72d85e5a0fd9c960b07b6f1c8875110701cb627
ARG EMSCRIPTEN_TAG=4.0.21
ARG BINARYEN_COMMIT=ecf25d6e6d20d2018c4897dcf95babdb16e7d311
ARG NODE_MAJOR=20

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  curl \
  build-essential \
  git \
  cmake \
  ninja-build \
  python3 \
  ca-certificates \
  linux-libc-dev

# Leave two cores free on a large machine. A small runner uses every core.
# taskset -c 0-6 assumed a 12-core box and failed anywhere smaller.
RUN printf '%s\n' \
  '#!/bin/sh' \
  'jobs=$(nproc)' \
  'if [ "$jobs" -gt 8 ]; then jobs=$((jobs - 2)); fi' \
  'exec ninja -j"$jobs" "$@"' \
  > /usr/local/bin/ninja-jobs && chmod +x /usr/local/bin/ninja-jobs

RUN mkdir -p /sources
WORKDIR /sources

# Full history is required: the pin is not the tip of branch p2996.
RUN git clone https://github.com/bloomberg/clang-p2996.git /sources/clang-p2996
WORKDIR /sources/clang-p2996
RUN git fetch --depth 1 origin ${P2996_COMMIT} && git checkout FETCH_HEAD

RUN mkdir build
WORKDIR /sources/clang-p2996/build

ENV CC=gcc CXX=g++

RUN cmake -G Ninja ../llvm \
  -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra" \
  -DLLVM_ENABLE_RUNTIMES="" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_BINDINGS=OFF \
  -DLLVM_BINDINGS_LIST="" \
  -DOCAMLFIND=OCAMLFIND-NOTFOUND \
  -DCLANGD_BUILD_XPC=OFF \
  -DCMAKE_INSTALL_PREFIX=/usr/local

RUN ninja-jobs install

WORKDIR /sources/clang-p2996
RUN mkdir build-libcxx
WORKDIR /sources/clang-p2996/build-libcxx

RUN cmake -G Ninja \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DLIBCXX_ENABLE_SHARED=YES \
  -DLIBCXX_ENABLE_STATIC=NO \
  -DLIBCXXABI_ENABLE_SHARED=YES \
  -DLIBCXXABI_ENABLE_STATIC=NO \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  ../runtimes

RUN ninja-jobs install-cxx install-cxxabi install-unwind

# Binaryen. Pin is the commit wasm-opt reported, not the version_125 tag
# (the working build is five commits after that tag).
RUN git clone https://github.com/WebAssembly/binaryen.git /sources/binaryen
WORKDIR /sources/binaryen
RUN git checkout ${BINARYEN_COMMIT}
RUN mkdir build
WORKDIR /sources/binaryen/build
RUN git -C /sources/binaryen submodule update --init
RUN cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_LLVM_DWARF=ON -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local
RUN ninja-jobs
RUN ninja-jobs install

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -
RUN apt-get install -y nodejs

# Emscripten. Tag pin: the working export said 4.0.21-git and did not keep .git.
RUN git clone --depth 1 --branch ${EMSCRIPTEN_TAG} https://github.com/emscripten-core/emscripten.git /sources/emscripten
WORKDIR /sources/emscripten
RUN ./bootstrap
COPY .emscripten /sources/emscripten/.emscripten
ENV EM_CONFIG=/sources/emscripten/.emscripten

# Swap emscripten's libcxx for clang-p2996's, then put emscripten's
# wasm-specific files back. Those files are what make libcxx link as wasm;
# the clang-p2996 copy is what makes reflection compile.
RUN mkdir /sources/emscripten-bak
RUN mv /sources/emscripten/system/lib/libcxx /sources/emscripten-bak/libcxx
RUN cp -a /sources/clang-p2996/libcxx /sources/emscripten/system/lib/libcxx
RUN cp /sources/emscripten-bak/libcxx/include/__config_site /sources/emscripten/system/lib/libcxx/include/__config_site
RUN cp /sources/emscripten-bak/libcxx/include/__config_site.in /sources/emscripten/system/lib/libcxx/include/__config_site.in
RUN cp /sources/emscripten-bak/libcxx/include/__assertion_handler /sources/emscripten/system/lib/libcxx/include/__assertion_handler
RUN cp /sources/emscripten-bak/libcxx/src/new.cpp /sources/emscripten/system/lib/libcxx/src/new.cpp
RUN cp /sources/emscripten-bak/libcxx/src/include/overridable_function.h \
       /sources/emscripten/system/lib/libcxx/src/include/overridable_function.h

ENV PATH="/sources/emscripten:/usr/local/bin:${PATH}"

WORKDIR /
COPY export-sysroot.sh /export-sysroot.sh
