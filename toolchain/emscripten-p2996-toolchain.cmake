# WebAssembly toolchain. em++ is the wrapper in the sysroot, which points
# EM_CONFIG at the sysroot's .emscripten, which points LLVM at the reflection clang.

if(DEFINED ENV{P2996_COMPILER_SYSROOT} AND NOT "$ENV{P2996_COMPILER_SYSROOT}" STREQUAL "")
  set(COMPILER_SYSROOT "$ENV{P2996_COMPILER_SYSROOT}")
elseif(P2996_COMPILER_SYSROOT)
  set(COMPILER_SYSROOT "${P2996_COMPILER_SYSROOT}")
else()
  set(COMPILER_SYSROOT "${CMAKE_SOURCE_DIR}/sysroot")
endif()

set(CMAKE_SYSTEM_NAME Emscripten)
set(EMSCRIPTEN 1 CACHE INTERNAL "If true, we are targeting Emscripten output.")

set(EMSCRIPTEN_ROOT_PATH ${COMPILER_SYSROOT}/emscripten)
list(APPEND CMAKE_MODULE_PATH "${EMSCRIPTEN_ROOT_PATH}/cmake/Modules")

set(CMAKE_C_COMPILER ${EMSCRIPTEN_ROOT_PATH}/emcc-wrapper.sh)
set(CMAKE_CXX_COMPILER ${EMSCRIPTEN_ROOT_PATH}/em++-wrapper.sh)

set(CMAKE_CXX_FLAGS_INIT "-std=c++26 -freflection -fparameter-reflection -fannotation-attributes -fexpansion-statements")

set(CMAKE_EXE_LINKER_FLAGS_INIT "-s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -lc++ -lc++abi -stdlib=libc++")

set(CMAKE_EXECUTABLE_SUFFIX ".html")

set(CMAKE_FIND_ROOT_PATH ${EMSCRIPTEN_ROOT_PATH})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
