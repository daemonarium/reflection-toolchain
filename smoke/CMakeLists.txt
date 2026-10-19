cmake_minimum_required(VERSION 3.17)
project(reflection_smoke CXX)

set(SMOKE_TESTS
  01_reflection
  02_parameter_reflection
  03_annotation_attributes
  04_expansion_statements
  05_libcxx
)
if(EMSCRIPTEN)
  list(APPEND SMOKE_TESTS 06_wasm_export)
endif()

enable_testing()

foreach(t IN LISTS SMOKE_TESTS)
  add_executable(${t} ${t}.cpp)
  if(EMSCRIPTEN)
    # Node must run main() to the end so the OK line and the status are visible.
    target_link_options(${t} PRIVATE "-s EXIT_RUNTIME=1")
  endif()
  add_test(NAME ${t} COMMAND ${t})
endforeach()
