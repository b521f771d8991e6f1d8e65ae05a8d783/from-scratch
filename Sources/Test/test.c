#include "test.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int get1FromC(void) {
  printf("Hello from C \n");
  return 1;
}

int main(void) {
  if (get1FromC() != 1 && get1FromCpp() != 1 && get1FromObjC() != 1 &&
      get1FromObjCpp() != 1) {
    return 1;
  }

  printf("All tests okay");
  return EXIT_SUCCESS;
}
