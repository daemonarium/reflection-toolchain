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

int main() {
  if (member_count() == 2) {
    std::cout << "OK reflection\n";
    return 0;
  }
  std::cout << "FAIL reflection " << member_count() << "\n";
  return 1;
}
