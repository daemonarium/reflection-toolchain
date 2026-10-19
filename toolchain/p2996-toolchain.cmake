# Native toolchain for the P2996 reflection clang in the exported sysroot.
# P2996_COMPILER_SYSROOT may be an environment variable or a -D cache entry.
# Otherwise the sysroot is expected next to this repository.

if(DEFINED ENV{P2996_COMPILER_SYSROOT} AND NOT "$ENV{P2996_COMPILER_SYSROOT}" STREQUAL "")
  set(COMPILER_SYSROOT "$ENV{P2996_COMPILER_SYSROOT}")
elseif(P2996_COMPILER_SYSROOT)
  set(COMPILER_SYSROOT "${P2996_COMPILER_SYSROOT}")
else()
  set(COMPILER_SYSROOT "${CMAKE_SOURCE_DIR}/sysroot")
endif()

set(CMAKE_SYSTEM_NAME Linux)

set(CMAKE_C_COMPILER "${COMPILER_SYSROOT}/usr/local/bin/clang")
set(CMAKE_CXX_COMPILER "${COMPILER_SYSROOT}/usr/local/bin/clang++")

set(LIBCXX_INCLUDE_DIR ${COMPILER_SYSROOT}/usr/include/c++/v1)
set(LIBCXX_LIB_DIR ${COMPILER_SYSROOT}/usr/lib)

set(LIBCXX_INCLUDE_DIR_ARCH ${COMPILER_SYSROOT}/usr/include/x86_64-linux-gnu/c++/v1)
set(LIBCXX_INCLUDE_DIR_GEN ${COMPILER_SYSROOT}/usr/include/c++/v1)

set(CMAKE_CXX_FLAGS_INIT "-std=c++26 -freflection -fparameter-reflection -fannotation-attributes -fexpansion-statements -nostdinc++ -I${LIBCXX_INCLUDE_DIR_ARCH} -I${LIBCXX_INCLUDE_DIR_GEN}")

set(CMAKE_EXE_LINKER_FLAGS_INIT "-L${LIBCXX_LIB_DIR} -Wl,-rpath,${LIBCXX_LIB_DIR} -lc++ -lc++abi -lunwind -stdlib=libc++")

set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES "")

set(CMAKE_FIND_ROOT_PATH ${COMPILER_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
