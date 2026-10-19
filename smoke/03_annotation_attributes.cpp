#include <iostream>
#include <meta>

struct tag {
  int value;
};

consteval tag mark() {
  return tag{7};
}

struct [[=mark()]] Holder {};

consteval int annotation_value() {
  for (auto annotation : std::meta::annotations_of(^^Holder)) {
    if (std::meta::type_of(annotation) == ^^tag) {
      return std::meta::extract<tag>(annotation).value;
    }
  }
  return -1;
}

int main() {
  if (annotation_value() == 7) {
    std::cout << "OK annotation-attributes\n";
    return 0;
  }
  std::cout << "FAIL annotation-attributes " << annotation_value() << "\n";
  return 1;
}
