FROM debian:12.11-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  curl \
  build-essential \
  git \
  cmake \
  ninja-build \
  python3 \
  util-linux \
  ca-certificates \
  linux-libc-dev 
  #\
  #&& rm -rf /var/lib/apt/lists/*

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
  -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra" \
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

# BINARYEN
RUN git clone https://github.com/WebAssembly/binaryen.git /sources/binaryen
WORKDIR /sources/binaryen
RUN mkdir build
WORKDIR /sources/binaryen/build
RUN git submodule update --init
RUN cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_LLVM_DWARF=ON -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local
RUN taskset -c 0-6 ninja
RUN taskset -c 0-6 ninja install

# NODE
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

# EMSCRIPTEN
RUN git clone https://github.com/emscripten-core/emscripten.git /sources/emscripten
WORKDIR /sources/emscripten
RUN ./bootstrap
COPY .emscripten /sources/emscripten/.emscripten
ENV EM_CONFIG=/sources/emscripten/.emscripten

# Replace libcxx with clang-p2996 and copy config

#RUN taskset -c 0-6 python3 embuilder.py build libc++ libc++abi

RUN mkdir /sources/emscripten-bak
RUN mv /sources/emscripten/system/lib/libcxx /sources/emscripten-bak/libcxx
#RUN mv /sources/emscripten/system/lib/libcxxabi /sources/emscripten-bak/libcxxabi

# Copy libcxx and libcxxabi from clang-p2996 to emscripten
#RUN cp -r /sources/emscripten/cache/sysroot/include/c++/v1 /sources/emscripten-bak/c++-v1
RUN cp -r /sources/clang-p2996/libcxx /sources/emscripten/system/lib/libcxx
#RUN cp -r /sources/clang-p2996/libcxx/include/* /sources/emscripten/cache/sysroot/include/c++/v1

# Copy from emscripten bak back to emscripten
#RUN cp /sources/emscripten-bak/c++-v1/__config_site /sources/emscripten/cache/sysroot/include/c++/v1/__config_site
RUN cp /sources/emscripten-bak/libcxx/include/__config_site /sources/emscripten/system/lib/libcxx/include/__config_site
RUN cp /sources/emscripten-bak/libcxx/include/__config_site.in /sources/emscripten/system/lib/libcxx/include/__config_site.in
RUN cp /sources/emscripten-bak/libcxx/include/__assertion_handler /sources/emscripten/system/lib/libcxx/include/__assertion_handler
RUN cp /sources/emscripten-bak/libcxx/src/new.cpp /sources/emscripten/system/lib/libcxx/src/new.cpp
RUN cp /sources/emscripten-bak/libcxx/src/include/overridable_function.h \
       /sources/emscripten/system/lib/libcxx/src/include/overridable_function.h

# Copy libcxxabi from clang-p2996 to emscripten
#RUN cp -r /sources/clang-p2996/libcxxabi /sources/emscripten/system/lib/libcxxabi
#RUN cp /sources/emscripten-bak/libcxxabi/src/stdlib_new_delete.cpp \
       #/sources/emscripten/system/lib/libcxxabi/src/stdlib_new_delete.cpp

# RUN taskset -c 0-6 python3 embuilder.py build \
#                libc++ libc++-debug libc++-noexcept libc++-debug-noexcept libc++-wasmexcept libc++-debug-wasmexcept \
#                libc++-mt libc++-debug-mt libc++-mt-noexcept libc++-debug-mt-noexcept \
#                libc++-mt-wasmexcept libc++-debug-mt-wasmexcept \
#                libc++abi libc++abi-debug libc++abi-noexcept libc++abi-debug-noexcept \
#                libc++abi-wasmexcept libc++abi-debug-wasmexcept \
#                libc++abi-mt libc++abi-debug-mt libc++abi-mt-noexcept libc++abi-debug-mt-noexcept \
#                libc++abi-mt-wasmexcept libc++abi-debug-mt-wasmexcept




#RUN python3 embuilder.py build ALL

WORKDIR /
COPY export-sysroot.sh /export-sysroot.sh

