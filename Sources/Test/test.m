#include "test.h"

#import <Foundation/Foundation.h>

@interface R1 : NSObject
- (int)return1;
@end

@implementation R1
- (int)return1 {
  return 1;
}
@end

int get1FromObjC(void) {
  NSLog(@"This is a test");
  return [[[R1 alloc] init] return1];
}