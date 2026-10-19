#include <emscripten.h>
#include <iostream>
#include <meta>

struct Point {
  int x;
  int y;
};

consteval int member_count() {
  int n = 0;
  for (auto member : std::meta::nonstatic_data_members_of(
         ^^Point, std::meta::access_context::unchecked())) {
    (void)member;
    ++n;
  }
  return n;
}

extern "C" EMSCRIPTEN_KEEPALIVE int reflected_members() {
  return member_count();
}

int main() {
  if (reflected_members() == 2) {
    std::cout << "OK wasm-export\n";
    return 0;
  }
  std::cout << "FAIL wasm-export " << reflected_members() << "\n";
  return 1;
}
