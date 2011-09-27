#import "ZEModel.h"
#import "ZEAppDelegate.h"
#import <objc/runtime.h>

@implementation ZEModel

- (id)entity {
    return [NSEntityDescription entityForName:[NSString stringWithUTF8String:class_getName([self class])] inManagedObjectContext:[ZEAppDelegate managedObjectContext]];
}

- (id)init {
    if ((self = [super initWithEntity:[self entity] insertIntoManagedObjectContext:[ZEAppDelegate managedObjectContext]])) {
        
    }
    
    return self;
}

@end
