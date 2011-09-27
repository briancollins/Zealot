#import "ZEReplayPlayer.h"
#import "ZEReplay.h"
#import "ZEPlayer.h"

@implementation ZEReplayPlayer
@dynamic race, team, replay, player, outcome, won;

- (void)willTurnIntoFault {
    self.race = nil;
    self.team = nil;
    self.replay = nil;
    self.player = nil;
    self.outcome = nil;
    self.won = nil;
    [super willTurnIntoFault];
}

@end
