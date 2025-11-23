FROM debian:12.11-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  cmake \
  ninja-build \
  python3 \
  util-linux \
  ca-certificates \
  linux-libc-dev \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /sources
WORKDIR /sources

RUN git clone https://github.com/bloomberg/clang-p2996.git

WORKDIR /sources/clang-p2996
RUN git checkout p2996

RUN mkdir build
WORKDIR /sources/clang-p2996/build

ENV CC=gcc CXX=g++

# (opcjonalnie ustaw prefix, żeby instalowało do /opt/llvm zamiast /usr/local)
# ENV LLVM_PREFIX=/opt/llvm

RUN cmake -G Ninja ../llvm \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
  -DLLVM_ENABLE_RUNTIMES="" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_BINDINGS=OFF \
  -DLLVM_BINDINGS_LIST="" \
  -DOCAMLFIND=OCAMLFIND-NOTFOUND \
  -DCLANGD_BUILD_XPC=OFF \
  -DCMAKE_INSTALL_PREFIX=/usr/local

# taskset jest w pakiecie util-linux
RUN taskset -c 0-6 ninja install

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

RUN taskset -c 6-12 ninja install-cxx install-cxxabi install-unwind # install-libc

COPY export-sysroot.sh /export-sysroot.sh

