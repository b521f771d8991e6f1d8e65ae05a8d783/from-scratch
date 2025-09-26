#import "test.h"
#include <memory>

#import <Foundation/Foundation.h>

class Test {
  int i = 0;

public:
  Test(const int &_i) : i(i) {}

  int getI() { return i; }
};

@interface Test1 : NSObject
+ (int)return1;
@end

@implementation Test1
+ (int)return1 {
  std::shared_ptr<Test> test = std::make_shared<Test>(1);
  return test->getI();
}
@end

extern "C" int get1FromObjCpp(void) {
  NSLog(@"This is a test");
  return [Test1 return1];
}