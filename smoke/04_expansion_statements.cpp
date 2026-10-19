#include <iostream>
#include <meta>

struct Point {
  int x;
  int y;
};

template <typename T>
int sum_members(const T& value) {
  // The member list is a vector, which is not a constant range.
  // define_static_array turns it into a span that `template for` can expand.
  constexpr auto members = std::define_static_array(
    std::meta::nonstatic_data_members_of(^^T, std::meta::access_context::unchecked()));
  int sum = 0;
  template for (constexpr auto member : members) {
    sum += value.[:member:];
  }
  return sum;
}

int main() {
  Point point{3, 4};
  if (sum_members(point) == 7) {
    std::cout << "OK expansion-statements\n";
    return 0;
  }
  std::cout << "FAIL expansion-statements " << sum_members(point) << "\n";
  return 1;
}
