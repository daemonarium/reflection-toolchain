set(P2996_ROOT "${CMAKE_SOURCE_DIR}/cpp-compiler/sysroot" CACHE PATH "p2996 sysroot")
set(P2996_CLANG "${P2996_ROOT}/usr/local/bin/clang++" CACHE FILEPATH "p2996 clang++")
set(P2996_CXX_INCLUDE "${P2996_ROOT}/usr/include/c++/v1")
set(P2996_CXX_INCLUDE_TRIPLET "${P2996_ROOT}/usr/include/x86_64-linux-gnu/c++/v1")
set(P2996_LIB_DIR "${P2996_ROOT}/usr/lib")

function(configure_p2996_compiler)
  if(EMSCRIPTEN)
    return()
  endif()
  if(EXISTS "${P2996_CLANG}")
    set(CMAKE_CXX_COMPILER "${P2996_CLANG}" CACHE FILEPATH "p2996 clang++" FORCE)
  endif()
endfunction()

function(apply_p2996_target TARGET)
  if(EMSCRIPTEN)
    return()
  endif()
  if(NOT EXISTS "${P2996_CLANG}")
    message(WARNING "p2996 clang not found at ${P2996_CLANG}; skipping p2996 flags for ${TARGET}")
    return()
  endif()

  target_compile_options(${TARGET} PRIVATE
    -nostdinc++
    -I${P2996_CXX_INCLUDE_TRIPLET}
    -I${P2996_CXX_INCLUDE}
  )
  target_link_options(${TARGET} PRIVATE
    -L${P2996_LIB_DIR}
    -Wl,-rpath,${P2996_LIB_DIR}
    -lc++
    -lc++abi
    -lunwind
  )
endfunction()

function(apply_p2996_rpath_origin TARGET)
  if(EMSCRIPTEN)
    return()
  endif()
  target_link_options(${TARGET} PRIVATE "-Wl,-rpath,$ORIGIN")
endfunction()

function(apply_p2996_plugin_target TARGET)
  apply_p2996_target(${TARGET})
  target_compile_options(${TARGET} PRIVATE
    -fmodules
    -fcxx-modules
    -fno-autolink
    -std=c++26
    -freflection
    -fparameter-reflection
    -fannotation-attributes
  )
endfunction()
