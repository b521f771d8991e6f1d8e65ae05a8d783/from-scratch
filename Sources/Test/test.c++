#include "test.h"

#include <iostream>

extern "C" int get1FromCpp(void) {
  std::cout << "Hello from C++" << std::endl;
  return 1;
}