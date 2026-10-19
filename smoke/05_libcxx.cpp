#include <algorithm>
#include <format>
#include <iostream>
#include <string>
#include <vector>

int main() {
  std::vector<int> values{3, 1, 2};
  std::ranges::sort(values);
  std::string text = std::format("{}-{}-{}", values[0], values[1], values[2]);
  if (text == "1-2-3") {
    std::cout << "OK libcxx\n";
    return 0;
  }
  std::cout << "FAIL libcxx " << text << "\n";
  return 1;
}
