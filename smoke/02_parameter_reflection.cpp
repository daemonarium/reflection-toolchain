#include <iostream>
#include <meta>

void sample(int count, double scale);

consteval int parameter_count() {
  int n = 0;
  for (auto parameter : std::meta::parameters_of(^^sample)) {
    (void)parameter;
    ++n;
  }
  return n;
}

int main() {
  if (parameter_count() == 2) {
    std::cout << "OK parameter-reflection\n";
    return 0;
  }
  std::cout << "FAIL parameter-reflection " << parameter_count() << "\n";
  return 1;
}
