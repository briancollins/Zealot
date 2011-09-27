#import "ZEPlayer.h"

@implementation ZEPlayer
@dynamic name, bnetId, region, replayPlayers;

- (void)willTurnIntoFault {
    self.name = nil;
    self.bnetId = nil;
    self.region = nil;
    self.replayPlayers = nil;
    [super willTurnIntoFault];
}

@end
