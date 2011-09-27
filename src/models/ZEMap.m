#import "ZEMap.h"

@implementation ZEMap
@dynamic name, replays;

- (void)willTurnIntoFault {
    self.name = nil;
    self.replays = nil;
    [super willTurnIntoFault];
}

@end
