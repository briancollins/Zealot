#import "ZEModel.h"
#import "ZEAppDelegate.h"
#import <objc/runtime.h>

@implementation ZEModel

- (id)entity {
    return [NSEntityDescription entityForName:[NSString stringWithUTF8String:class_getName([self class])] inManagedObjectContext:[ZEAppDelegate managedObjectContext]];
}

@end
